# frozen_string_literal: true

# Facade for classroom presentation logic
class ClassroomFacade
  attr_reader :classroom

  def initialize(classroom)
    @classroom = classroom
  end

  # Get all students for this classroom (both via enrollments and legacy classroom_id)
  #
  # @return [ActiveRecord::Relation<Student>]
  def students
    enrolled_student_ids = classroom.current_students.pluck(:id)
    legacy_student_ids = classroom.users.students.kept.pluck(:id)
    all_student_ids = (enrolled_student_ids + legacy_student_ids).uniq

    Student.kept.where(id: all_student_ids).includes(
      :portfolio,
      :orders,
      portfolio: :portfolio_transactions
    )
  end
end
