class RemoveMissedDaysFromGradeEntries < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :grade_entries, :days_missed, :bigint )
  end
end
