class AddArchivedToStocks < ActiveRecord::Migration[8.0]
  def change
    add_column :stocks, :archived, :boolean, default: false, null: false
  end
end
