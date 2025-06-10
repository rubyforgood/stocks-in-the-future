# frozen_string_literal: true

class RemovePriceInfoFromStocks < ActiveRecord::Migration[7.1]
  def change
    remove_column :stocks, :price_info, :json
  end
end
