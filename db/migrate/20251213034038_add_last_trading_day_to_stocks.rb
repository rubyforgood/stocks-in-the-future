class AddLastTradingDayToStocks < ActiveRecord::Migration[8.1]
  def change
    add_column :stocks, :last_trading_day, :date
  end
end
