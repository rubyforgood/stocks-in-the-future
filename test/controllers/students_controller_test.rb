require "test_helper"

class StudentsControllerTest < ActionDispatch::IntegrationTest
  test "should show student" do
    student = create(:user)

    get student_path(student)

    assert_response :success
  end
end
