class AddTradingEnabledToClassrooms < ActiveRecord::Migration[8.0]
  def change
    add_column :classrooms, :trading_enabled, :boolean, default: false, null: false
  end
end
