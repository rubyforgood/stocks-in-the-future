# frozen_string_literal: true

require "test_helper"

class TeacherTest < ActiveSupport::TestCase
  test "inherits from User" do
    teacher = create(:teacher)
    assert_kind_of User, teacher
    assert_equal "Teacher", teacher.type
  end

  test "email is required" do
    teacher = build(:teacher, email: nil)
    refute teacher.valid?
    assert_includes teacher.errors[:email], "can't be blank"
  end

  test "can manage students in same classroom" do
    classroom = create(:classroom)
    teacher = create(:teacher, classroom: classroom)
    student = create(:student, classroom: classroom)

    assert_equal classroom, teacher.classroom
    assert_equal classroom, student.classroom
  end
end
