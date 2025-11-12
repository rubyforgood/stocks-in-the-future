class RenameStudentClassroomsToEnrollments < ActiveRecord::Migration[8.0]
  def change
    safety_assured { rename_table :student_classrooms, :enrollments }
  end
end