class CreateTableRelations < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :classroom, foreign_key: true

    create_table :portfolios do |t|
      t.references :user, null: false, foreign_key: true
      t.float :cash_balance
      t.float :current_position
      t.json :transactions

      t.timestamps
    end

    create_table :portfolio_transactions do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.integer :actor_id, null: false
      t.integer :transaction_type

      t.timestamps
    end

    create_table :companies do |t|
      t.string :company_name
      t.json :company_info

      t.timestamps
    end
    add_index :companies, :company_name, unique: true

    create_table :stocks do |t|
      t.string :ticker
      t.json :price_info
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :stocks, :ticker, unique: true

    create_table :portfolio_stocks do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.float :shares
      t.float :purchase_price

      t.timestamps
    end

    add_index :portfolio_stocks, [:portfolio_id, :stock_id], unique: true, name: "index_portfolio_stocks_on_portfolio_and_stock"    
  end
end
