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
    assert_not teacher.valid?
    assert_includes teacher.errors[:email], "can't be blank"
  end

  test "username is automatically set to email" do
    teacher = create(:teacher, email: "jane@school.com")
    assert_equal "jane@school.com", teacher.username
  end

  test "username updates when email changes" do
    teacher = create(:teacher, email: "jane@school.com")
    teacher.update!(email: "jane.new@school.com")
    assert_equal "jane.new@school.com", teacher.username
  end

  test "display_name returns name field" do
    teacher = create(:teacher, name: "Jane Smith")
    assert_equal "Jane Smith", teacher.display_name
  end

  test "display_name falls back to email prefix when name is blank" do
    teacher = create(:teacher, name: nil, email: "jane@school.com")
    assert_equal "jane", teacher.display_name
  end

  test "can manage students in same classroom" do
    classroom = create(:classroom)
    teacher = create(:teacher, classroom: classroom)
    student = create(:student, classroom: classroom)

    assert_equal classroom, teacher.classroom
    assert_equal classroom, student.classroom
  end
end
