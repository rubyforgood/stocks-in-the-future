class CreateAnnouncments < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.string :title
      t.text :body

      t.timestamps
    end
  end
end
