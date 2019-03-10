class Price < ApplicationRecord

  def self.calc(user, price)
    temp = Price.where(user: user).order("original_price ASC NULLS LAST").pluck(:original_price, :convert_price)
    new_price = 0
    tt = 0.0
    temp.each_cons(2) do |a, b|
      if price.to_i >= a[0] && price.to_i < b[0] then
        new_price = (a[1].to_i + (b[1].to_i - a[1].to_i).to_f / (b[0].to_i - a[0].to_i).to_f * (price.to_i - a[0].to_i)).round(0)
        break
      end
      tt = (b[1].to_i / b[0].to_i).to_f
    end
    if new_price == 0 then
      new_price = (tt * price.to_i).round(0)
    end
    return new_price
  end

end
