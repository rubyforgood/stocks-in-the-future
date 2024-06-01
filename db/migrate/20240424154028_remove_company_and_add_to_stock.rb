class RemoveCompanyAndAddToStock < ActiveRecord::Migration[7.1]
  def up
    remove_reference :stocks, :company, foreign_key: true

    drop_table :companies

    add_column :stocks, :stock_exchange, :string

    change_table :stocks, bulk: true do |t|
      t.string :company_name
      t.string :company_website
      t.text :description
      t.string :industry
      t.text :management
      t.integer :employees
      t.text :competitor_names

      t.decimal :sales_growth, precision: 15, scale: 2
      t.decimal :industry_avg_sales_growth, precision: 15, scale: 2
      t.decimal :debt_to_equity, precision: 15, scale: 2
      t.decimal :industry_avg_debt_to_equity, precision: 15, scale: 2
      t.decimal :profit_margin, precision: 15, scale: 2
      t.decimal :industry_avg_profit_margin, precision: 15, scale: 2
      t.decimal :cash_flow, precision: 15, scale: 2
      t.decimal :debt, precision: 15, scale: 2
    end
  end

  def down
    raise "Irreversible migration"
  end
end
