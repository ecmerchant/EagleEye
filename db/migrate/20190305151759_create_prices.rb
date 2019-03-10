class CreatePrices < ActiveRecord::Migration[5.2]
  def change
    create_table :prices do |t|
      t.string :user
      t.integer :original_price
      t.integer :convert_price

      t.timestamps
    end
  end
end
