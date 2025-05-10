require "test_helper"

class ClassroomTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:classroom).validate!
  end
end
