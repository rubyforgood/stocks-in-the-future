class AddIsPerfectAttendanceToGradeEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :grade_entries, :is_perfect_attendance, :boolean, default: false, null: false
  end
end
