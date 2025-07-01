class RemoveTransactionsFromPortfolios < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :portfolios, :transactions, :json }
  end
end
