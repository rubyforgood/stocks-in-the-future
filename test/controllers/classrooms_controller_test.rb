require "test_helper"

class ClassroomsControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    sign_in users(:one)

    get classrooms_url

    assert_response :success
  end

  test "new" do
    sign_in users(:one)

    get new_classroom_path

    assert_response :success
  end

  test "create" do
    params = {
      classroom: {
        grade: "3rd",
        name: "Ms. Smith",
        school_id: schools(:armistead_elementary).id,
        year_id: years(:current).id
      }
    }
    sign_in users(:one)

    assert_difference("Classroom.count") do
      post(classrooms_path, params:)
    end

    assert_redirected_to classroom_url(Classroom.last)
  end

  # TODO: test a failed create

  test "show" do
    sign_in users(:one)

    get classroom_path(classrooms(:hubbard_5th_grade))

    assert_response :success
  end

  test "edit" do
    sign_in users(:one)

    get edit_classroom_path(classrooms(:hubbard_5th_grade))

    assert_response :success
  end

  test "update" do
    classroom = classrooms(:hubbard_5th_grade)
    params = {classroom: {grade: "4th"}}
    sign_in users(:one)

    assert_changes -> { classroom.updated_at } do
      patch(classroom_path(classroom), params:)
      classroom.reload
    end

    assert_redirected_to classroom_url(classroom)
  end

  # TODO: test a failed update

  # TODO: would need dependent destroy on user
  # test "should destroy classroom" do
  #   assert_difference("Classroom.count", -1) do
  #     delete classroom_url(@classroom)
  #   end

  #   assert_redirected_to classrooms_url
  # end
end
