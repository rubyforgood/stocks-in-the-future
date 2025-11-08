# frozen_string_literal: true

require "test_helper"

class StudentClassroomTest < ActiveSupport::TestCase
  test "belongs to student" do
    student = create(:student)
    classroom = create(:classroom)
    student_classroom = StudentClassroom.create!(student: student, classroom: classroom)

    assert_equal student, student_classroom.student
  end

  test "belongs to classroom" do
    student = create(:student)
    classroom = create(:classroom)
    student_classroom = StudentClassroom.create!(student: student, classroom: classroom)

    assert_equal classroom, student_classroom.classroom
  end

  test "validates uniqueness of student_id scoped to classroom_id" do
    student = create(:student)
    classroom = create(:classroom)

    StudentClassroom.create!(student: student, classroom: classroom)

    assert_raises(ActiveRecord::RecordInvalid) do
      StudentClassroom.create!(student: student, classroom: classroom)
    end
  end

  test "archived defaults to false" do
    student = create(:student)
    classroom = create(:classroom)
    student_classroom = StudentClassroom.create!(student: student, classroom: classroom)

    assert_equal false, student_classroom.archived
  end

  test "can mark classroom as archived" do
    student = create(:student)
    classroom = create(:classroom)
    student_classroom = StudentClassroom.create!(student: student, classroom: classroom, archived: true)

    assert_equal true, student_classroom.archived
  end
end
