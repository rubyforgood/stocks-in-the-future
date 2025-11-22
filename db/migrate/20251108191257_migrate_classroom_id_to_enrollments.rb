class MigrateClassroomIdToEnrollments < ActiveRecord::Migration[8.0]
  def up
    User.where(type: "Student").where.not(classroom_id: nil).each do |student|
      Enrollment.find_or_create_by(student_id: student.id, classroom_id: student.classroom_id)
    end
  end

  def down
    
  end
end
