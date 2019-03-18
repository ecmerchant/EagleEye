class ListsController < ApplicationController

  require 'csv'

  def show
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)
    current_seller_id = @account.seller_id

    csv = nil
    @headers = Array.new
    File.open('app/others/Flat.File.Listingloader.jp.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
      csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
      csv.each do |row|
        @headers.push(row)
      end
    end
    @lists = List.where(user: user, seller_id: current_seller_id, ng_flg: false)

    @body = Array.new
    @template = ListTemplate.where(user: user, list_type: '相乗り')

    @lists.each do |temp|
      thash = Hash.new
      @template.each do |ch|
        thash[ch.header] = ch.value
      end

      @headers[2].each do |col|
        case col
        when 'sku' then
          thash['sku'] = temp.seller_id.to_s + "_" + temp.asin
        when 'price' then
          thash['price'] = temp.list_price
        when 'product-id' then
          thash['product-id'] = temp.asin
        when 'product-id-type' then
          thash['product-id-type'] = 'ASIN'
        when 'condition_type' then
          thash['condition-type'] = temp.condition
        else

        end
      end
      @body.push(thash)
    end

    respond_to do |format|
      format.html do
          #html用の処理を書く
      end
      format.csv do
        fname = "アマゾン出品ファイル_" + Time.now.strftime("%Y%m%D%H%M%S") + ".txt"
        send_data render_to_string, filename: fname, type: :csv
      end
    end
  end

  def regist
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)
    current_seller_id = @account.seller_id
    @lists = List.where(user: user, seller_id: current_seller_id, ng_flg: false)

    flg_list = Array.new

    @lists.each do |list|
      flg_list << List.new(user: user, asin: list.asin, list_flg: true)
    end
    List.import flg_list, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:list_flg]}
    redirect_to lists_check_path
  end

  def check
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)
    current_seller_id = @account.seller_id
    temp = List.where(user: user, list_flg: true)
    @asins = temp.group(:asin).pluck(:asin)
    @sellers = temp.group(:seller_id).pluck(:seller_id)

    respond_to do |format|
      format.html
        if request.post? then
          data = params[:asin_del]
          logger.debug("======== DEL ===========")
          if data != nil then
            ext = File.extname(data.path)
            if ext == ".xls" || ext == ".xlsx" then
              logger.debug("=== delete ===")
              workbook = RubyXL::Parser.parse(data.path)
              worksheet = workbook[0]

              worksheet.each_with_index do |row, i|
                if i > 0 then
                  if row[0] == nil then break end
                  if row[0].value == nil then break end
                  ng = row[0].value.to_s

                  temp.where(asin: ng).update(
                    list_flg: false
                  )

                end
              end
            end
          end
          redirect_to lists_check_path
        end
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook[0]

        user = current_user.email
        @sheet.add_cell(0, 0, "削除ASIN")
        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "削除ASINテンプレート.xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end

  end

end
