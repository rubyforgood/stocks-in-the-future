class AddDiscardedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :discarded_at, :datetime
  end
end