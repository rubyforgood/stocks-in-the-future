# frozen_string_literal: true

class ChangePriceToPriceCentsOnStocks < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        rename_column :stocks, :price, :price_cents
        change_column :stocks, :price_cents, :integer
      end

      dir.down do
        rename_column :stocks, :price_cents, :price
        change_column :stocks, :price, :decimal
      end
    end
  end
end
