class CreatePortfolios < ActiveRecord::Migration[7.1]
  def change
    create_table :portfolios do |t|
      t.references :user, null: false, foreign_key: true
      t.float :cash_balance
      t.float :current_position
      t.json :transactions

      t.timestamps
    end
  end
end
