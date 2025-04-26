require "test_helper"

class ClassroomTest < ActiveSupport::TestCase
  test "factory" do
    assert build(:classroom).validate!
  end

  test "destroy" do
    assert classrooms(:hubbard_5th_grade).destroy!
  end
end
