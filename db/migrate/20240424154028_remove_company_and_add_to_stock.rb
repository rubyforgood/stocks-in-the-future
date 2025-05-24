# standard:disable Rails/ReversibleMigration
class RemoveCompanyAndAddToStock < ActiveRecord::Migration[7.1]
  def change
    remove_reference :stocks, :company, foreign_key: true

    drop_table :companies

    add_column :stocks, :stock_exchange, :string

    add_column :stocks, :company_name, :string
    add_column :stocks, :company_website, :string
    add_column :stocks, :description, :text
    add_column :stocks, :industry, :string
    add_column :stocks, :management, :text
    add_column :stocks, :employees, :integer
    add_column :stocks, :competitor_names, :text

    add_column :stocks, :sales_growth, :decimal, precision: 15, scale: 2
    add_column :stocks, :industry_avg_sales_growth, :decimal, precision: 15, scale: 2
    add_column :stocks, :debt_to_equity, :decimal, precision: 15, scale: 2
    add_column :stocks, :industry_avg_debt_to_equity, :decimal, precision: 15, scale: 2
    add_column :stocks, :profit_margin, :decimal, precision: 15, scale: 2
    add_column :stocks, :industry_avg_profit_margin, :decimal, precision: 15, scale: 2
    add_column :stocks, :cash_flow, :decimal, precision: 15, scale: 2
    add_column :stocks, :debt, :decimal, precision: 15, scale: 2
  end
end
# rubocop:enable Rails/ReversibleMigration
