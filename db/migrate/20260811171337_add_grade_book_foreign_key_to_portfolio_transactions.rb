# frozen_string_literal: true

# The foreign key for the column added in the previous migration, unvalidated first and then validated,
# which is the form strong_migrations asks for: adding a validated key in one step holds a write lock while
# every existing row is checked.
class AddGradeBookForeignKeyToPortfolioTransactions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_foreign_key :portfolio_transactions, :grade_books, validate: false
    validate_foreign_key :portfolio_transactions, :grade_books
  end

  def down
    remove_foreign_key :portfolio_transactions, :grade_books
  end
end
