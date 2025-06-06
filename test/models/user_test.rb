require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:student).validate!
  end

  test "validate uniqueness of email" do
    create(:student, email: "test@example.com")
    new_student = build(:student, email: "test@example.com")

    assert_not new_student.valid?
    assert_includes new_student.errors[:email], "has already been taken"
  end
end
