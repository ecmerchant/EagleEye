class ProductsController < ApplicationController

  before_action :authenticate_user!, :except => [:regist]
  protect_from_forgery :except => [:regist]

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
    @lists = List.where(user: user, seller_id: current_seller_id, ng_flg: false).page(params[:page]).per(500)
    @total = List.where(user: user, seller_id: current_seller_id).count
    @ng_count = List.where(user: user, seller_id: current_seller_id, ng_flg: true).count
    if request.post? then
      seller_id = params[:seller_id]
      if seller_id == nil then
        return
      end
      @account.update(
        seller_id: seller_id
      )
      #AmazonProduct.search(user, seller_id)
      tlists = List.where(user: user, seller_id: current_seller_id, ng_flg: true)
      flg_list = Array.new
      tlists.each do |list|
        flg_list << List.new(user: user, asin: list.asin, ng_flg: false)
      end
      List.import flg_list, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:ng_flg]}

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
          data3 = params[:ng_key_del]
          data4 = params[:ng_brand_del]
          logger.debug("======== 11G ===========")
          if data1 != nil || data2 != nil then
            logger.debug("======== REG ===========")
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
                    if row[0] == nil then break end
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
          else
            logger.debug("======== DEL ===========")
            if data3 != nil then
              stype = "キーワード"
              data = data3
            else
              stype = "ブランド名"
              data = data4
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

                    ts = Setting.find_by(
                      user: user,
                      ng_type: stype,
                      keyword: ng
                    )

                    if ts != nil then
                      ts.delete
                    end

                  end
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
        send_data data, filename: "除外設定テンプレート.xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end
  end

  def check
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)
    current_seller_id = @account.seller_id
    lists = List.where(user: user, seller_id: current_seller_id)
    sets = Setting.where(user: user)
    ng_keywords = sets.where(ng_type: "キーワード").group(:keyword).pluck(:keyword)
    ng_brands = sets.where(ng_type: "ブランド名").group(:keyword).pluck(:keyword)
    ng_asins = List.where(user: user, list_flg: true).group(:asin).pluck(:asin)

    flg_list = Array.new

    lists.each do |list|
      title = list.amazon_product.title
      brand = list.amazon_product.brand
      asin = list.asin
      ng_flg = false

      if ng_asins.include?(asin) then
        ng_flg = true
      else
        nl = ng_keywords.select do |t|
          title.include?(t)
        end

        if nl[0] != nil then
          ng_flg = true
        else
          if brand != nil then
            nl = ng_brands.select do |t|
              brand.include?(t)
            end
            if nl[0] != nil then
              ng_flg = true
            else
              ng_flg = false
            end
          else
            ng_flg = false
          end
        end
      end
      flg_list << List.new(user: user, asin: list.asin, ng_flg: ng_flg)
    end
    List.import flg_list, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:ng_flg]}

    redirect_back(fallback_location: root_path)
  end

  def clear
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)
    current_seller_id = @account.seller_id
    lists = List.where(user: user, seller_id: current_seller_id, ng_flg: true)
    flg_list = Array.new

    lists.each do |list|
      flg_list << List.new(user: user, asin: list.asin, ng_flg: false)
    end

    List.import flg_list, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:ng_flg]}
    redirect_back(fallback_location: root_path)
  end


  def delete
    @login_user = current_user
    user = current_user.email
    if request.post? then
      data = params[:chk]
      temp = List.where(user: user)
      data.each do |key, value|
        tg = temp.find(key)
        if tg != nil then
          tg.delete
        end
      end
      redirect_back(fallback_location: root_path)
    end
  end


  def regist
    if request.post? then
      logger.debug("====== Regist from Form Start =======")
      user = params[:user]
      password = params[:password]
      if User.find_by(email: user) == nil then
        #新規登録
        init_password = password
        tuser = User.create(email: user, password: init_password, admin_flg: false)
        Account.find_or_create_by(user: user)
        return
      end
    end
  end

end
