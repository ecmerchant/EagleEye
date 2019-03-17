class ListTemplatesController < ApplicationController

  def setup
    @login_user = current_user
    user = current_user.email
    @headers = Array.new
    @template = ListTemplate.where(user: user, list_type: '相乗り')

    File.open('app/others/Flat.File.Header.txt', 'r', encoding: 'Windows-31J', undef: :replace, replace: '*') do |file|
      csv = CSV.new(file, encoding: 'Windows-31J', col_sep: "\t")
      csv.each do |row|
        @headers.push(row)
      end
    end
    if request.post? then
      data = params[:text]
      data.each do |key, value|
        tp = ListTemplate.find_or_create_by(user: user, list_type: '相乗り', header: key)
        tp.update(
          value: value
        )
      end
    end
  end

end
