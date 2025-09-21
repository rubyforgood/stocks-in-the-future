# frozen_string_literal: true

class AddIndexDiscardedAtToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :users, :discarded_at, algorithm: :concurrently
  end
end
