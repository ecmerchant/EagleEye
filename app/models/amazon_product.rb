class AmazonProduct < ApplicationRecord
  has_many :lists
  require 'open-uri'
  require 'nokogiri'

  def self.search(user, seller_id)
    logger.debug("======== Search Start ========")

    option = {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36"
    }
    url = "https://www.amazon.co.jp/s?merchant=" + seller_id.to_s + "&page=1"
    charset = nil
    html = open(url, option) do |f|
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
      title = node.xpath('.//h2')[0].inner_text
      brand = /<span class="a-size-small a-color-secondary"><\/span><span class="a-size-small a-color-secondary">([\s\S]*?)<\/span>/.match(body)
      if brand != nil then
        brand = brand[1]
      else
        brand = nil
      end
      logger.debug(title)
      logger.debug(brand)

      if price != nil then
        price = price.inner_text
        if price.include?("-") then
          logger.debug("============= Variation ================")
          page = "https://www.amazon.co.jp/dp/" + asin.to_s + "/?m=" + seller_id.to_s
          logger.debug(page)
          charset = nil
          html = open(page, option) do |f|
            charset = f.charset
            f.read
          end
          doc = Nokogiri::HTML.parse(html, nil, charset)

          price = doc.xpath('.//span[@id="price_inside_buybox"]')[0]
          if price != nil then
            price = price.inner_text
            price = price.gsub("￥", "").gsub(",", "")
            price = price.strip
          else
            price = 0
          end
          logger.debug(price)

          buf = doc.xpath('.//div[@id="variation_color_name"]')[0]
          if buf != nil then
            variation = buf.xpath('.//li')
            variation.each do |temp|
              var_asin = temp.attribute("data-defaultasin").value
              var_price = temp.xpath('.//span[@class="a-size-mini twisterSwatchPrice"]')[0]
              if var_price != nil then
                var_price = var_price.inner_text
                var_price = var_price.gsub("￥", "").gsub(",", "")
                var_price = var_price.strip
              else
                var_price = 0
              end
              buf1 << AmazonProduct.new(asin: var_asin, title: title, brand: brand)
              buf2 << List.new(user: user, asin: var_asin, seller_id: seller_id, seller_price: var_price, list_price: Price.calc(user, var_price))
            end
          end
        else
          price = price.gsub("￥", "").gsub(",", "")
          price = price.strip
          logger.debug(price)
          buf1 << AmazonProduct.new(asin: asin, title: title, brand: brand)
          buf2 << List.new(user: user, asin: asin, seller_id: seller_id, seller_price: price, list_price: Price.calc(user, price))
        end
      end
    end
    AmazonProduct.import buf1, on_duplicate_key_update: {constraint_name: :for_upsert_amazon_products, columns: [:title, :brand, :updated_at]}
    List.import buf2, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:seller_id, :seller_price, :list_price]}

  end

end
