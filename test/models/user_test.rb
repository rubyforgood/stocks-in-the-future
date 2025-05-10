require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:user).validate!
  end
end
