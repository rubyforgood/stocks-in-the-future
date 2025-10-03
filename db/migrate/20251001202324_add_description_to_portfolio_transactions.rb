class AddDescriptionToPortfolioTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :portfolio_transactions, :description, :text
  end
end
