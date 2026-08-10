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
      # Cents, summed as integers and divided once by whoever displays it. This summed
      # `calculate_total_value`, which is already `cents / 100.0` - so it added a float per student and
      # the repo's own rule is that integer cents are authoritative and the round trip loses value.
      total_portfolio_value_cents: students.includes(:portfolio).sum do |student|
        student.portfolio&.calculate_total_value_cents || 0
      end,
      recent_orders_count: Order.joins(:user).where(users: { classroom: classroom }).where(
        "orders.created_at > ?",
        1.week.ago
      ).count
    }
  end
end
