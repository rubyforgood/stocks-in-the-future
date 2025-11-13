# frozen_string_literal: true

require "test_helper"

class EnrollmentTest < ActiveSupport::TestCase
  test "belongs to student" do
    student = create(:student)
    classroom = create(:classroom)
    enrollment = Enrollment.create!(student: student, classroom: classroom)

    assert_equal student, enrollment.student
  end

  test "belongs to classroom" do
    student = create(:student)
    classroom = create(:classroom)
    enrollment = Enrollment.create!(student: student, classroom: classroom)

    assert_equal classroom, enrollment.classroom
  end

  test "validates uniqueness of student_id scoped to classroom_id" do
    student = create(:student)
    classroom = create(:classroom)

    Enrollment.create!(student: student, classroom: classroom)

    assert_raises(ActiveRecord::RecordInvalid) do
      Enrollment.create!(student: student, classroom: classroom)
    end
  end

  test "archived defaults to false" do
    student = create(:student)
    classroom = create(:classroom)
    enrollment = Enrollment.create!(student: student, classroom: classroom)

    assert_equal false, enrollment.archived
  end

  test "can mark classroom as archived" do
    student = create(:student)
    classroom = create(:classroom)
    enrollment = Enrollment.create!(student: student, classroom: classroom, archived: true)

    assert_equal true, enrollment.archived
  end

  test "student can enroll in multiple classrooms" do
    student = create(:student)
    initial_count = student.enrollments.count # Factory may create a default enrollment
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)

    Enrollment.create!(student: student, classroom: classroom1)
    Enrollment.create!(student: student, classroom: classroom2)

    assert_equal initial_count + 2, student.enrollments.count
    assert_includes student.classrooms, classroom1
    assert_includes student.classrooms, classroom2
  end
end
