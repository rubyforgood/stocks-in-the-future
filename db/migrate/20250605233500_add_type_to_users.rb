# frozen_string_literal: true

# Adds a type column to the users table to support STI
class AddTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :type, :string, default: "User", null: false
    change_column_null :users, :type, false
  end
end
