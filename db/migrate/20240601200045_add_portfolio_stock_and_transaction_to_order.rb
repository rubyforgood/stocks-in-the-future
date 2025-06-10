# frozen_string_literal: true

class AddPortfolioStockAndTransactionToOrder < ActiveRecord::Migration[7.1]
  def change
    add_reference :orders, :portfolio_stock, null: true, foreign_key: true
    add_reference :orders, :portfolio_transaction, null: true, foreign_key: true
  end
end
