require "test_helper"

class SchoolTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:school).validate!
  end

  test "destroy" do
    assert schools(:armistead_elementary).destroy!
  end
end
