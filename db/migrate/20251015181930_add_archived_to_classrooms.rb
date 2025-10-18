class AddArchivedToClassrooms < ActiveRecord::Migration[8.0]
  def change
    add_column :classrooms, :archived, :boolean, default: false, null: false
  end
end
