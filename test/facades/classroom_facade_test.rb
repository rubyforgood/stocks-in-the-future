# frozen_string_literal: true

require "test_helper"

class ClassroomFacadeTest < ActiveSupport::TestCase
  test "students returns students enrolled via enrollments" do
    classroom = create(:classroom)
    student = create(:student)
    create(:classroom_enrollment, student: student, classroom: classroom)

    facade = ClassroomFacade.new(classroom)

    assert_includes facade.students, student
  end

  test "students returns students assigned via legacy classroom_id" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)

    facade = ClassroomFacade.new(classroom)

    assert_includes facade.students, student
  end

  test "students returns both enrollment and legacy students without duplicates" do
    classroom = create(:classroom)

    # Student with enrollment
    student_with_enrollment = create(:student)
    create(:classroom_enrollment, student: student_with_enrollment, classroom: classroom)

    # Student with legacy classroom_id
    student_with_legacy = create(:student, classroom: classroom)

    facade = ClassroomFacade.new(classroom)
    students = facade.students

    assert_equal 2, students.count
    assert_includes students, student_with_enrollment
    assert_includes students, student_with_legacy
  end

  test "students does not return duplicate if student has both enrollment and classroom_id" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)
    create(:classroom_enrollment, student: student, classroom: classroom)

    facade = ClassroomFacade.new(classroom)
    students = facade.students

    assert_equal 1, students.count
    assert_includes students, student
  end

  test "students only returns current enrollments, not historical" do
    classroom = create(:classroom)
    current_student = create(:student)
    historical_student = create(:student)

    create(:classroom_enrollment,
           student: current_student,
           classroom: classroom,
           unenrolled_at: nil)
    create(:classroom_enrollment,
           student: historical_student,
           classroom: classroom,
           unenrolled_at: 1.week.ago)

    facade = ClassroomFacade.new(classroom)
    students = facade.students

    assert_includes students, current_student
    assert_not_includes students, historical_student
  end

  test "students excludes discarded students" do
    classroom = create(:classroom)
    active_student = create(:student, classroom: classroom)
    discarded_student = create(:student, classroom: classroom)
    discarded_student.discard

    facade = ClassroomFacade.new(classroom)
    students = facade.students

    assert_includes students, active_student
    assert_not_includes students, discarded_student
  end

  test "students includes necessary associations for performance" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)
    portfolio = create(:portfolio, user: student)
    create(:order, user: student)
    create(:portfolio_transaction, portfolio: portfolio)

    facade = ClassroomFacade.new(classroom)

    # Should not raise N+1 queries when accessing associations
    assert_nothing_raised do
      facade.students.each do |s|
        s.portfolio
        s.orders.to_a
        s.portfolio&.portfolio_transactions&.to_a
      end
    end
  end
end
