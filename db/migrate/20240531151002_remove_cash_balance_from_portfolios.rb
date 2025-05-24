# standard:disable Rails/ReversibleMigration
class RemoveCashBalanceFromPortfolios < ActiveRecord::Migration[7.1]
  def change
    remove_column :portfolios, :cash_balance
  end
end
# rubocop:enable Rails/ReversibleMigration
