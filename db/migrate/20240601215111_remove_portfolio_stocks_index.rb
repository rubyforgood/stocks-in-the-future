# frozen_string_literal: true

# standard:disable Rails/ReversibleMigration
class RemovePortfolioStocksIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :portfolio_stocks, name: 'index_portfolio_stocks_on_portfolio_and_stock'

    add_index :portfolio_stocks, %i[portfolio_id stock_id], name: 'index_portfolio_stocks_on_portfolio_and_stock'
  end
end
