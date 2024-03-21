class RemoveNotNullConstraintFromStockIdInCompanies < ActiveRecord::Migration[7.1]
  def change
    change_column_null :companies, :stock_id, true
  end
end
