class RemoveNotNullConstraintFromPortfolioStocks < ActiveRecord::Migration[7.1]
  def change
    change_column_null :portfolio_stocks, :stock_id, true
    change_column_null :portfolio_stocks, :portfolio_id, true
  end
end
