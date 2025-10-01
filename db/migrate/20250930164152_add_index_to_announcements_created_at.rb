class AddIndexToAnnouncementsCreatedAt < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :announcements, :created_at, order: { created_at: :desc }, algorithm: :concurrently
  end
end
