class SearchAmazonJob < ApplicationJob
  queue_as :search_amazon

  rescue_from(StandardError) do |exception|
    logger.debug("===== Standard Error Escape Active Job ======")
    logger.error exception
  end

  def perform(user, seller_id)
    AmazonProduct.search(user, seller_id)
  end
end
