class AmazonProduct < ApplicationRecord
  has_many :lists
  require 'open-uri'
  require 'nokogiri'

  def self.search(user, seller_id)
    logger.debug("======== Search Start ========")
    url = "https://www.amazon.co.jp/s?merchant=" + seller_id.to_s + "&page=1"
    charset = nil
    html = open(url) do |f|
      charset = f.charset
      f.read
    end

    doc = Nokogiri::HTML.parse(html, nil, charset)
    buf1 = Array.new
    buf2 = Array.new

    doc.xpath('//li[@class="s-result-item s-result-card-for-container-noborder s-carded-grid celwidget  "]').each do |node|
      asin = node.attribute("data-asin").value
      logger.debug(asin)
      price = node.xpath('.//span[@class="a-size-base a-color-price s-price a-text-bold"]')[0]
      body = node.inner_html

      if price != nil then
        price = price.inner_text
        if price.include?("-") then
          price = /-([\s\S]*?)$/.match(price)[1]
          price = price.gsub("￥", "").gsub(",", "")
          price = price.strip
          logger.debug(price)
        else
          price = price.gsub("￥", "").gsub(",", "")
          price = price.strip
          logger.debug(price)
        end

        title = node.xpath('.//h2')[0].inner_text
        brand = /<span class="a-size-small a-color-secondary"><\/span><span class="a-size-small a-color-secondary">([\s\S]*?)<\/span>/.match(body)[1]
        logger.debug(title)
        logger.debug(brand)
        buf1 << AmazonProduct.new(asin: asin, title: title, brand: brand)
        buf2 << List.new(user: user, asin: asin, seller_id: seller_id, seller_price: price, list_price: Price.calc(user, price))
      end
    end
    AmazonProduct.import buf1, on_duplicate_key_update: {constraint_name: :for_upsert_amazon_products, columns: [:title, :brand, :updated_at]}
    List.import buf2, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:seller_id, :seller_price, :list_price]}

  end

end
