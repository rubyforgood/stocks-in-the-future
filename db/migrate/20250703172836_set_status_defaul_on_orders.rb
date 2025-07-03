class SetStatusDefaulOnOrders < ActiveRecord::Migration[8.0]
  def change
    change_column_default :orders, :status, 0
  end
end
