class AddStockToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_reference :companies, :stock, foreign_key: true
  end
end
