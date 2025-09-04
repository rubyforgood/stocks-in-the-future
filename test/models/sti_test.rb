# frozen_string_literal: true

require "test_helper"

class StiTest < ActiveSupport::TestCase
  def test_sti_implementation
    classroom = create(:classroom)

    admin = create(:admin, classroom: classroom)
    assert_equal "User", admin.type

    student = create(:student, classroom: classroom)
    assert_equal "Student", student.type

    teacher = create(:teacher, classroom: classroom)
    assert_equal "Teacher", teacher.type

    admin.update(type: "Student")
    assert_equal "Student", admin.type

    assert_equal 3, User.count
    assert_equal 2, Student.count
    assert_equal 1, Teacher.count

    assert_equal "Student", admin.reload.type
    assert_equal "Student", student.reload.type
    assert_equal "Teacher", teacher.reload.type
  end
end
