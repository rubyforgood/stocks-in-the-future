class RemoveActorIdFromPortfolioTransactions < ActiveRecord::Migration[7.1]
  def change
    remove_reference :portfolio_transactions, :actor
  end
end
