class AddTransactionFeeToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :transaction_fee_cents, :integer, null: false, default: 0
  end
end
