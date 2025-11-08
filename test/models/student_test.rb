# frozen_string_literal: true

require "test_helper"

class StudentTest < ActiveSupport::TestCase
  test "inherits from User" do
    student = create(:student)
    assert_kind_of User, student
    assert_equal "Student", student.type
  end

  test "belongs to classroom" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)
    assert_equal classroom, student.classroom
  end

  test "has many classrooms through student_classrooms" do
    student = create(:student)
    initial_classroom_count = student.classrooms.count  # Factory creates 1 default classroom
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)

    student.student_classrooms.create!(classroom: classroom1)
    student.student_classrooms.create!(classroom: classroom2)

    assert_equal initial_classroom_count + 2, student.classrooms.count
    assert_includes student.classrooms, classroom1
    assert_includes student.classrooms, classroom2
  end

  test "can have archived classroom in history" do
    student = create(:student)
    initial_count = student.student_classrooms.count  # Factory creates 1 default join record
    classroom1 = create(:classroom)
    classroom2 = create(:classroom)

    student.student_classrooms.create!(classroom: classroom1, archived: false)
    student.student_classrooms.create!(classroom: classroom2, archived: true)

    assert_equal initial_count + 2, student.student_classrooms.count
    assert_equal initial_count + 1, student.student_classrooms.where(archived: false).count
    assert_equal 1, student.student_classrooms.where(archived: true).count
  end

  test "has portfolio association" do
    student = create(:student)
    portfolio = create(:portfolio, user: student)
    assert_equal portfolio, student.portfolio
  end

  test "email can be blank for students" do
    student = build(:student, email: "")
    assert student.valid?
  end

  test "password generation works" do
    student = create(:student)
    assert_not_nil student.encrypted_password
  end

  test "destroy raises and does not delete the row" do
    student = create(:student)
    assert_raises(RuntimeError) { student.destroy }
    assert student.reload.persisted?
    assert_not student.discarded?
  end
end
