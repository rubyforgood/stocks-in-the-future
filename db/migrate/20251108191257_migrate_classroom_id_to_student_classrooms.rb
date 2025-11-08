class MigrateClassroomIdToStudentClassrooms < ActiveRecord::Migration[8.0]
  def up
    User.where(type: "Student").where.not(classroom_id: nil).each do |student|
      StudentClassroom.find_or_create_by(student_id: student.id, classroom_id: student.classroom_id)
    end
  end

  def down
    # Reversing this migration would lose data, so we skip it
  end
end
