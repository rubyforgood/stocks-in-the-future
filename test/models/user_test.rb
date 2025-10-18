# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "returns true when the user holds the stock" do
    student = create(:student, :with_portfolio)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: student.portfolio, stock: stock)
    assert student.holding?(stock)
  end

  test "returns false when the user does not hold the stock" do
    student = create(:student, :with_portfolio)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: student.portfolio, stock: stock, shares: 0)
    assert_not student.holding?(stock)
  end

  test "factory" do
    assert build(:student).validate!
  end

  test "validate uniqueness of email" do
    create(:student, email: "test@example.com")
    new_student = build(:student, email: "test@example.com")

    assert_not new_student.valid?
    assert_includes new_student.errors[:email], "has already been taken"
  end

  test "student? returns true for Student type" do
    student = create(:student)
    assert student.student?
    assert_not student.teacher?
    assert_not student.teacher_or_admin?
  end

  test "teacher? returns true for Teacher type" do
    teacher = create(:teacher)
    assert teacher.teacher?
    assert teacher.teacher_or_admin?
    assert_not teacher.student?
  end

  test "teacher_or_admin? returns true for admin users" do
    admin = create(:admin)
    assert admin.teacher_or_admin?
    assert_not admin.student?
  end

  test "email is optional for students" do
    student = build(:student, email: nil)
    assert student.valid?
  end

  test "email uniqueness constraint allows nil values" do
    create(:student, email: nil)
    student2 = build(:student, email: nil)
    assert student2.valid?
  end

  test "email uniqueness constraint prevents duplicate emails" do
    create(:student, email: "test@example.com")
    student2 = build(:student, email: "test@example.com")
    assert_not student2.valid?
    assert_includes student2.errors[:email], "has already been taken"
  end

  test "username is required for all students" do
    user = build(:student, username: nil)
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "username must be unique" do
    create(:student, username: "testuser")
    user2 = build(:student, username: "testuser")
    assert_not user2.valid?
    assert_includes user2.errors[:username], "has already been taken"
  end

  test "type must be valid STI class" do
    user = build(:student, type: "InvalidType")
    assert_not user.valid?
    assert_includes user.errors[:type], "is not included in the list"
  end

  test "students and teacher scopes returns only correct type users" do
    student = create(:student)
    teacher = create(:teacher)

    students = User.students
    assert_includes students, student
    assert_not_includes students, teacher

    teachers = User.teachers
    assert_includes teachers, teacher
    assert_not_includes teachers, student
  end

  test "display_name returns username when present" do
    user = create(:student, username: "testuser")
    assert_equal "testuser", user.display_name
  end

  test "display_name returns email prefix when username blank" do
    user = build(:student, username: "", email: "test@example.com")
    user.save(validate: false) # Skip validation for this test
    assert_equal "test", user.display_name
  end
end
