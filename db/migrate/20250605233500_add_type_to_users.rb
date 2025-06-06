# frozen_string_literal: true

class AddTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :type, :string, default: 'User', null: false
    change_column_null :users, :type, false
  end
end
