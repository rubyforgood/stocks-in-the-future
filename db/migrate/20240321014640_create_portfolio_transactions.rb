class CreatePortfolioTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :portfolio_transactions do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.integer :actor_id, null: false
      t.integer :transaction_type

      t.timestamps
    end
  end
end
