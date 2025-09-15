class AddYesterdayPriceCentsToStocks < ActiveRecord::Migration[8.0]
  def change
    add_column :stocks, :yesterday_price_cents, :integer
  end
end
