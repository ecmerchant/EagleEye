class CreateLists < ActiveRecord::Migration[5.2]
  def change
    create_table :lists do |t|
      t.string :user
      t.string :asin
      t.string :seller_id
      t.integer :seller_price
      t.integer :list_price
      t.string :condition

      t.timestamps
    end
  end
end
