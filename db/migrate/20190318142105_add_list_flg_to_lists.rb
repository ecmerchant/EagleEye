class AddListFlgToLists < ActiveRecord::Migration[5.2]
  def change
    add_column :lists, :list_flg, :boolean, default: false
  end
end
