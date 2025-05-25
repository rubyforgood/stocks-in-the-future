require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:user).validate!
  end

  test "validate uniqueness of email" do
    create(:user, email: "test@example.com")
    new_user = build(:user, email: "test@example.com")

    assert_not new_user.valid?
    assert_includes new_user.errors[:email], "has already been taken"
  end
end
