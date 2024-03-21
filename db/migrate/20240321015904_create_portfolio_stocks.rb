class CreatePortfolioStocks < ActiveRecord::Migration[7.1]
  def change
    create_table :portfolio_stocks do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.float :shares
      t.float :purchase_price

      t.timestamps
    end
  end
end
