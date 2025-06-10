# frozen_string_literal: true

class AddNotNullConstraintToTransactionTypeOnProtfolioTransactions < ActiveRecord::Migration[7.2]
  def change
    change_column_null(:portfolio_transactions, :transaction_type, false)
  end
end
