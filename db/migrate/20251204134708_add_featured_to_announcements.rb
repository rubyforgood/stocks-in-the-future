class AddFeaturedToAnnouncements < ActiveRecord::Migration[8.1]
  def change
    add_column :announcements, :featured, :boolean, default: false, null: false
  end
end
