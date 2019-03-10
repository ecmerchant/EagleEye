class ProductsController < ApplicationController

  def search
    @login_user = current_user
    user = current_user.email
    @account = Account.find_or_create_by(user: user)
    @headers = {
      asin: "ASIN",
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
      AmazonProduct.search(user, seller_id)
      redirect_back(fallback_location: root_path)
    end
  end

end
