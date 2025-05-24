# standard:disable Rails/ReversibleMigration

class ChangeFloatToBigDecimalPortfolioStocks < ActiveRecord::Migration[7.1]
  def change
    change_column :portfolio_stocks, :shares, :decimal, precision: 15, scale: 2
    change_column :portfolio_stocks, :purchase_price, :decimal, precision: 15, scale: 2
  end
end
# rubocop:enable Rails/ReversibleMigration
