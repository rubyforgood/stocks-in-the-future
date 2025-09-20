class CreatePortfolioSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolio_snapshots do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :worth_cents, null: false

      t.timestamps
    end

    add_index :portfolio_snapshots, [:portfolio_id, :date], unique: true
  end
end
