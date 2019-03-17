class ProductsController < ApplicationController

  def search
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)
    @headers = {
      asin: "ASIN",
      title: "商品名",
      brand: "ブランド名",
      seller_id: "セラーID",
      seller_price: "セラー価格",
      list_price: "出品価格"
    }
    current_seller_id = @account.seller_id
    @lists = List.where(user: user, seller_id: current_seller_id)
    @total = @lists.count
    if request.post? then
      seller_id = params[:seller_id]
      if seller_id == nil then
        return
      end
      @account.update(
        seller_id: seller_id
      )
      #AmazonProduct.search(user, seller_id)
      SearchAmazonJob.perform_later(user, seller_id)
      redirect_back(fallback_location: root_path)
    end
  end

  def setup
    @login_user = current_user
    user = current_user.email
    @keywords = Setting.where(user: user, ng_type: "キーワード")
    @brands = Setting.where(user: user, ng_type: "ブランド名")

    respond_to do |format|
      format.html
        if request.post? then
          data1 = params[:ng_key]
          data2 = params[:ng_brand]
          if data1 != nil then
            stype = "キーワード"
            data = data1
          else
            stype = "ブランド名"
            data = data2
          end

          if data != nil then
            ext = File.extname(data.path)
            if ext == ".xls" || ext == ".xlsx" then
              logger.debug("=== UPLOAD ===")
              workbook = RubyXL::Parser.parse(data.path)
              worksheet = workbook[0]

              worksheet.each_with_index do |row, i|
                if i > 0 then
                  if row[0].value == nil then break end
                  ng = row[0].value.to_s

                  Setting.find_or_create_by(
                    user: user,
                    ng_type: stype,
                    keyword: ng
                  )
                end
              end
            end
          end
          redirect_to products_setup_path
        end
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook[0]

        user = current_user.email

        @sheet.add_cell(0, 0, "登録データ")

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "NG設定テンプレート.xlsx", type: "application/xlsx", disposition: "attachment"

      end
    end

  end

end
