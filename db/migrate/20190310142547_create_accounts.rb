class CreateAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts do |t|
      t.string :user
      t.string :seller_id
      t.string :feed_id
      t.datetime :feed_upload
      t.string :process

      t.timestamps
    end
  end
end
