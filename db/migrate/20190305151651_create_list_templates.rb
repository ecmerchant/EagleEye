class CreateListTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :list_templates do |t|
      t.string :user
      t.string :list_type
      t.string :header
      t.text :value

      t.timestamps
    end
  end
end
