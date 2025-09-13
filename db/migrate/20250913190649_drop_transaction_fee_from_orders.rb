class DropTransactionFeeFromOrders < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      remove_column :orders, :transaction_fee_cents, :integer, default: 0, null: false
    end
  end
end
