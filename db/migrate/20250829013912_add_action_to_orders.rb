class AddActionToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :action, :string, null: false, default: "sell"
    
    change_column_default :orders, :action, from: "sell", to: nil
  end
end
