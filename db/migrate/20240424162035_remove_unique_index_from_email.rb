# frozen_string_literal: true

class RemoveUniqueIndexFromEmail < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, :email
  end
end
