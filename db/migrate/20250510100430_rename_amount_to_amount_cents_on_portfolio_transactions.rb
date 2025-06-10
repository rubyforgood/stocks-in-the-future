# frozen_string_literal: true

class RenameAmountToAmountCentsOnPortfolioTransactions < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        rename_column(:portfolio_transactions, :amount, :amount_cents)
        change_column(
          :portfolio_transactions,
          :amount_cents,
          :integer,
          null: false
        )
      end

      dir.down do
        rename_column(:portfolio_transactions, :amount_cents, :amount)
        change_column(
          :portfolio_transactions,
          :amount,
          :decimal,
          precision: 15,
          scale: 2,
          null: false
        )
      end
    end
  end
end
