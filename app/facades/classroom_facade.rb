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

  def stats
    return {} unless classroom

    students = classroom.users.students.kept
    {
      total_students: students.count,
      active_students: students.joins(:orders).distinct.count,
      total_portfolio_value: students.includes(:portfolio).sum do |student|
        student.portfolio&.calculate_total_value || 0
      end,
      recent_orders_count: Order.joins(:user).where(users: { classroom: classroom }).where(
        "orders.created_at > ?",
        1.week.ago
      ).count
    }
  end
end
