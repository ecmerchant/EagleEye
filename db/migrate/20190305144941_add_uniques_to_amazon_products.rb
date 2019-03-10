class AddUniquesToAmazonProducts < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      ALTER TABLE amazon_products
        ADD CONSTRAINT for_upsert_amazon_products UNIQUE ("asin");
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE amazon_products
        DROP CONSTRAINT for_upsert_amazon_products;
    SQL
  end
end
