class AddPerfectWeeksToGradeEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :grade_entries, :perfect_weeks, :bigint
  end
end
