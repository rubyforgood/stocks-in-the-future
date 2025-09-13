class AddReasonToPortfolioTransaction < ActiveRecord::Migration[8.0]
  def change
    add_column :portfolio_transactions, :reason, :string
  end
end
