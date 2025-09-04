# frozen_string_literal: true

require "test_helper"

class StiTest < ActiveSupport::TestCase
  def test_sti_implementation
    # Create a classroom for the users
    classroom = create(:classroom)

    # Test creating an Admin
    admin = create(:admin, classroom: classroom)
    assert_equal "User", admin.type

    # Test creating a Student
    student = create(:student, classroom: classroom)
    assert_equal "Student", student.type

    # Test creating a Teacher
    teacher = create(:teacher, classroom: classroom)
    assert_equal "Teacher", teacher.type

    # Test updating an Admin to be a Student
    admin.update(type: "Student")
    assert_equal "Student", admin.type

    # Verify that the records are saved correctly
    assert_equal 3, User.count
    assert_equal 2, Student.count
    assert_equal 1, Teacher.count

    # Verify that the type field is set correctly
    assert_equal "Student", admin.reload.type
    assert_equal "Student", student.reload.type
    assert_equal "Teacher", teacher.reload.type
  end
end
