class CreateAmazonProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :amazon_products do |t|
      t.string :asin
      t.text :title
      t.string :image1
      t.string :image2
      t.string :image3
      t.string :image4
      t.string :image5
      t.string :image6
      t.string :image7
      t.string :image8
      t.text :description
      t.text :detail
      t.string :brand
      t.string :part_number
      t.string :category_id

      t.timestamps
    end
  end
end
