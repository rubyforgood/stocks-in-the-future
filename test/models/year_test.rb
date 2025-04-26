require "test_helper"

class YearTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:year).validate!
  end

  test "destroy" do
    assert years(:current).destroy!
  end
end
