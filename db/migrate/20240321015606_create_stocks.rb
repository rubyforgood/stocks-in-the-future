class CreateStocks < ActiveRecord::Migration[7.1]
  def change
    create_table :stocks do |t|
      t.string :ticker
      t.json :price_info
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end

    add_reference :companies, :stock, null: false, foreign_key: true
    add_index :stocks, :ticker, unique: true
  end
end
