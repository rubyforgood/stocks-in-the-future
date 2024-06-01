require "test_helper"

class StudentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:one)
  end

  test "should show student" do
    get student_url(@student)
    assert_response :success
  end
end
