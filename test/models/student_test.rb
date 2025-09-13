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
    refute student.discarded?
  end
end
