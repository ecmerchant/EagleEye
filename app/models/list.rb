class List < ApplicationRecord
  belongs_to :amazon_product, primary_key: 'asin', foreign_key: 'asin', optional: true
end
