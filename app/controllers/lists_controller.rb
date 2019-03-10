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
    @lists = List.where(user: user, seller_id: current_seller_id)

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
end
