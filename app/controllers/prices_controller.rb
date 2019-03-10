class PricesController < ApplicationController

  def edit
    user = current_user.email
    @prices = Price.where(user: user).order("original_price ASC NULLS LAST")
    @login_user = current_user

    if request.post? then
      data = params[:price_edit]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xls" || ext == ".xlsx" then

          temp = Price.where(user: current_user.email)
          if temp != nil then
            temp.delete_all
          end
          logger.debug("=== UPLOAD ===")

          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook[0]
          worksheet.each_with_index do |row, i|
            if row[0].value == nil then break end

            from = row[0].value.to_i
            to = row[1].value.to_i
            Price.find_or_create_by(
              user: user,
              original_price: from,
              convert_price: to
            )

          end
        end
      end
      redirect_to prices_edit_path
    end

  end
end
