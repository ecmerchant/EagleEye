class PricesController < ApplicationController

  def edit
    user = current_user.email
    @prices = Price.where(user: user).order("original_price ASC NULLS LAST")
    @login_user = current_user

    respond_to do |format|
      format.html
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
                if i > 0 then
                  if row[0].value == nil then break end
                  logger.debug(row[1].value)
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
          end
          redirect_to prices_edit_path
        end
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook[0]

        user = current_user.email

        @sheet.add_cell(0, 0, "仕入価格")
        @sheet.add_cell(0, 1, "販売価格")

        buf = [1,1000,5000,10000,50000,100000,150000,300000,500000,1000000,5000000,10000000]

        buf.each_with_index do |tp, index|
          @sheet.add_cell(1 + index, 0, tp)
          @sheet.add_cell(1 + index, 1, tp)
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "価格テーブルテンプレート.xlsx", type: "application/xlsx", disposition: "attachment"

      end
    end
  end
  
end
