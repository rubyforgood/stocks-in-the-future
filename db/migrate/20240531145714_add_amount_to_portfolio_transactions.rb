class AddAmountToPortfolioTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :portfolio_transactions, :amount, :decimal, precision: 8, scale: 2, null: false
  end
end
