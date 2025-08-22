class RemovePerfectWeeksFromGradeEntries < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :grade_entries, :perfect_weeks, :bigint }
  end
end
