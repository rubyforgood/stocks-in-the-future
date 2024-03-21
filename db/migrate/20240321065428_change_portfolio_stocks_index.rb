class ChangePortfolioStocksIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :portfolio_stocks, name: "index_portfolio_stocks_on_portfolio_id"
    remove_index :portfolio_stocks, name: "index_portfolio_stocks_on_stock_id"
    add_index :portfolio_stocks, [:portfolio_id, :stock_id], unique: true, name: "index_portfolio_stocks_on_stock_and_portfolio"
  end
end
