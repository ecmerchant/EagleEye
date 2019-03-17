class AddNgFlgToLists < ActiveRecord::Migration[5.2]
  def change
    add_column :lists, :ng_flg, :boolean, default: false
  end
end
