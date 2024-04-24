class DropUnusedTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :stock_dividends
    drop_table :stock_prices
  end
end
