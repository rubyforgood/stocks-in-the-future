require "test_helper"

class StockTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:stock).validate!
  end
end
