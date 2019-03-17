class AmazonProduct < ApplicationRecord
  has_many :lists
  require 'open-uri'
  require 'nokogiri'

  def self.search(user, seller_id)
    logger.debug("======== Search Start ========")
    ua = CSV.read('app/others/User-Agent.csv', headers: false, col_sep: "\t")
    account = Account.find_by(user: user)
    sets = Setting.where(user: user)

    ng_keywords = sets.where(ng_type: "キーワード").group(:keyword).pluck(:keyword)
    ng_brands = sets.where(ng_type: "ブランド名").group(:keyword).pluck(:keyword)

    counter = 0
    account.update(
      process: counter.to_s + "件取得済み"
    )

    (1..400).each do |page|
      logger.debug(ua.sample[0])
      option = {
        "User-Agent" => ua.sample[0]
      }

      ahash = Hash.new

      url = "https://www.amazon.co.jp/s?merchant=" + seller_id.to_s + "&page=" + page.to_s
      charset = nil

      begin
        html = open(url, option) do |f|
          charset = f.charset
          f.read
        end
      rescue => e
        puts e
        account.update(
          process: "取得中断" + counter.to_s + "件取得済み"
        )
        return
      end

      doc = Nokogiri::HTML.parse(html, nil, charset)
      buf1 = Array.new
      buf2 = Array.new
      logger.debug("========== page access ===========")
      logger.debug(url)
      if doc.xpath('//li[@class="s-result-item s-result-card-for-container-noborder s-carded-grid celwidget  "]')[0] == nil then
        logger.debug("NO ITEM")
        if html.include?('action="/errors/validateCaptcha"') then
          logger.debug("=============== ACCESS DINIED ====================")
          account.update(
            process: "取得中断 全" + counter.to_s + "件"
          )
          break
        else
          logger.debug(html)
          logger.debug("=============== NO ITEM ====================")
          account.update(
            process: "取得完了 全" + counter.to_s + "件"
          )
          break
        end
      end

      doc.xpath('//li[@class="s-result-item s-result-card-for-container-noborder s-carded-grid celwidget  "]').each do |node|
        asin = node.attribute("data-asin").value
        price = node.xpath('.//span[@class="a-size-base a-color-price s-price a-text-bold"]')[0]

        if price != nil then
          body = node.inner_html
          title = node.xpath('.//h2')[0].inner_text
          brand = /<span class="a-size-small a-color-secondary"><\/span><span class="a-size-small a-color-secondary">([\s\S]*?)<\/span>/.match(body)
          if brand != nil then
            brand = brand[1]
          else
            brand = nil
          end
          price = price.inner_text
          logger.debug(asin)
          logger.debug(title)
          logger.debug(brand)

          if price.include?("-") then
            logger.debug("============= Variation ================")
            cp = "https://www.amazon.co.jp/dp/" + asin.to_s + "/?m=" + seller_id.to_s
            logger.debug(cp)
            charset = nil

            sleep(Random.rand*2.0)
            begin
              html2 = open(cp, option) do |f|
                charset = f.charset
                f.read
              end
            rescue => e
              puts e
              account.update(
                process: "取得中断" + counter.to_s + "件取得済み"
              )
              return
            end

            doc2 = Nokogiri::HTML.parse(html2, nil, charset)
            buf = doc2.xpath('.//div[@id="variation_color_name"]')[0]
            if buf != nil then
              variation = buf.xpath('.//li')
              variation.each do |temp|
                var_asin = temp.attribute("data-defaultasin").value
                var_price = temp.xpath('.//span[@class="a-size-mini twisterSwatchPrice"]')[0]
                if var_price != nil then
                  var_price = var_price.inner_text
                  var_price = var_price.gsub("￥", "").gsub(",", "")
                  var_price = var_price.strip
                  if ahash.has_key?(var_asin) == false then
                    counter += 1
                    nl = ng_keywords.select do |t|
                      title.include?(t)
                    end

                    ng_flg = false

                    if nl[0] != nil then
                      ng_flg = true
                    else
                      nl = ng_brands.select do |t|
                        brand.include?(t)
                      end
                      if nl[0] != nil then
                        ng_flg = true
                      else
                        ng_flg = false
                      end
                    end

                    buf1 << AmazonProduct.new(asin: var_asin, title: title, brand: brand)
                    buf2 << List.new(user: user, asin: var_asin, seller_id: seller_id, seller_price: var_price.to_i, list_price: Price.calc(user, var_price.to_i), ng_flg: ng_flg)
                    account.update(
                      process: counter.to_s + "件取得済み"
                    )
                    ahash[var_asin] = var_price
                  end
                else
                  logger.debug("----------------------------------------")
                  bufq = doc2.xpath('.//div[@id="bottomRow"]')[0].inner_html
                  bufk = /"asinVariationValues"([\s\S]*?)\}\}/.match(bufq)[0]
                  jbuf = JSON.parse("{" + bufk + "}")

                  option = {
                    "User-Agent" => ua.sample[0]
                  }
                  logger.debug("----=====-----")
                  jbuf["asinVariationValues"].each do |key, value|
                    jvasin = key.to_s
                    url2 = "https://www.amazon.co.jp/dp/" + jvasin.to_s + "/?m=" + seller_id.to_s + "&th=1&psc=1"

                    sleep(Random.rand*2.0)
                    begin
                      html3 = open(url2, option) do |f|
                        charset = f.charset
                        f.read
                      end
                    rescue => e
                      puts e
                      account.update(
                        process: "取得中断" + counter.to_s + "件取得済み"
                      )
                      return
                    end
                    doc3 = Nokogiri::HTML.parse(html3, nil, charset)
                    logger.debug(url2)
                    nprice = doc3.xpath('.//span[@id="priceblock_ourprice"]')[0]
                    if nprice != nil then
                      nprice = nprice.inner_text
                      nprice = nprice.gsub("￥", "").gsub(",", "")
                      nprice = nprice.strip
                    else
                      nprice = 0
                    end
                    if price != 0 then
                      new_p =  Price.calc(user, nprice.to_i).to_i
                      if ahash.has_key?(jvasin) == false then
                        counter += 1

                        nl = ng_keywords.select do |t|
                          title.include?(t)
                        end

                        ng_flg = false

                        if nl[0] != nil then
                          ng_flg = true
                        else
                          nl = ng_brands.select do |t|
                            brand.include?(t)
                          end
                          if nl[0] != nil then
                            ng_flg = true
                          else
                            ng_flg = false
                          end
                        end

                        buf1 << AmazonProduct.new(asin: jvasin, title: title, brand: brand)
                        buf2 << List.new(user: user, asin: jvasin, seller_id: seller_id, seller_price: nprice.to_i, list_price: new_p, ng_flg: ng_flg)
                        account.update(
                          process: counter.to_s + "件取得済み"
                        )
                        ahash[jvasin] = nprice
                      end
                    end
                  end
                end

              end
            end
          else
            price = price.gsub("￥", "").gsub(",", "")
            price = price.strip
            logger.debug(price)
            if ahash.has_key?(asin) == false then
              counter += 1
              nl = ng_keywords.select do |t|
                title.include?(t)
              end

              ng_flg = false

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

              buf1 << AmazonProduct.new(asin: asin, title: title, brand: brand)
              buf2 << List.new(user: user, asin: asin, seller_id: seller_id, seller_price: price.to_i, list_price: Price.calc(user, price.to_i), ng_flg: ng_flg)
              ahash[asin] = price.to_i
              account.update(
                process: counter.to_s + "件取得済み"
              )
            end
          end
        end
      end
      AmazonProduct.import buf1, on_duplicate_key_update: {constraint_name: :for_upsert_amazon_products, columns: [:title, :brand, :updated_at]}
      List.import buf2, on_duplicate_key_update: {constraint_name: :for_upsert_lists, columns: [:seller_id, :seller_price, :list_price, :ng_flg]}
      account.update(
        process: counter.to_s + "件取得済み"
      )
      logger.debug(url)
    end
  end

end
