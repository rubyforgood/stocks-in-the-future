# frozen_string_literal: true

require "test_helper"

class StiTest < ActiveSupport::TestCase
  def test_sti_implementation
    # Create a classroom for the users
    classroom = create(:classroom)

    # Test creating an Admin
    admin = create(:admin, classroom: classroom)
    puts "Admin created with type: #{admin.type}, valid?: #{admin.valid?}, errors: #{admin.errors.full_messages}"
    assert_equal "User", admin.type

    # Test creating a Student
    student = create(:student, classroom: classroom)
    puts "Student created with type: #{student.type}, " \
         "valid?: #{student.valid?}, " \
         "errors: #{student.errors.full_messages}"
    assert_equal "Student", student.type

    # Test creating a Teacher
    teacher = create(:teacher, classroom: classroom)
    puts "Teacher created with type: #{teacher.type}, " \
         "valid?: #{teacher.valid?}, " \
         "errors: #{teacher.errors.full_messages}"
    assert_equal "Teacher", teacher.type

    # Test updating an Admin to be a Student
    admin.update(type: "Student")
    puts "Admin updated to type: #{admin.type}, valid?: #{admin.valid?}, errors: #{admin.errors.full_messages}"
    assert_equal "Student", admin.type

    # Verify that the records are saved correctly
    puts "User count: #{User.count}"
    puts "Student count: #{Student.count}"
    puts "Teacher count: #{Teacher.count}"
    assert_equal 3, User.count
    assert_equal 2, Student.count
    assert_equal 1, Teacher.count

    # Verify that the type field is set correctly
    assert_equal "Student", admin.reload.type
    assert_equal "Student", student.reload.type
    assert_equal "Teacher", teacher.reload.type
  end
end
