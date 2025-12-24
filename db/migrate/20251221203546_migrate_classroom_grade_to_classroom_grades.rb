class MigrateClassroomGradeToClassroomGrades < ActiveRecord::Migration[8.1]
  class Classroom < ActiveRecord::Base
    self.table_name = "classrooms"
  end

  class Grade < ActiveRecord::Base
    self.table_name = "grades"
  end

  class ClassroomGrade < ActiveRecord::Base
    self.table_name = "classroom_grades"
  end

  def up
    Classroom.reset_column_information

    Classroom.find_each do |classroom|
      grade_number = classroom.grade
      raise "Grade not found for classroom #{classroom.id}" unless grade_number

      grade = Grade.find_by(level: grade_number)
      raise "Grade with level #{grade_number} not found" unless grade

      classroom_grade = ClassroomGrade.create!(grade_id: grade.id, classroom_id: classroom.id)
    end

    safety_assured { remove_column :classrooms, :grade }
  end

  def down
    add_column :classrooms, :grade, :integer
    Classroom.reset_column_information

    Classroom.find_each do |classroom|
      level = classroom.classroom_grade&.grade&.level
      classroom.update_column(:grade, level) if level
    end
  end
end
