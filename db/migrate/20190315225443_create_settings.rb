class CreateSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :settings do |t|
      t.string :user
      t.string :ng_type
      t.text :keyword

      t.timestamps
    end
  end
end
