class AddAttendanceDaysToGradeEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :grade_entries, :attendance_days, :bigint
  end
end
