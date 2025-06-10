# frozen_string_literal: true

class AddPriceToStocks < ActiveRecord::Migration[7.1]
  def change
    add_column :stocks, :price, :decimal
  end
end
