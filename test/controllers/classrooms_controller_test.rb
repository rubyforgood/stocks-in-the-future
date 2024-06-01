require "test_helper"

class ClassroomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @classroom = classrooms(:one)
    @user = users(:one) # Assuming you have a user fixture named :one
    sign_in @user # S
  end

  test "should get index" do
    get classrooms_url
    assert_response :success
  end

  test "should get new" do
    get new_classroom_url
    assert_response :success
  end

  test "should create classroom" do
    assert_difference("Classroom.count") do
      post classrooms_url, params: {classroom: {grade: @classroom.grade, name: @classroom.name, school_id: @classroom.school_id, year_id: @classroom.year_id}}
    end

    assert_redirected_to classroom_url(Classroom.last)
  end

  test "should show classroom" do
    get classroom_url(@classroom)
    assert_response :success
  end

  test "should get edit" do
    get edit_classroom_url(@classroom)
    assert_response :success
  end

  test "should update classroom" do
    patch classroom_url(@classroom), params: {classroom: {grade: @classroom.grade, name: @classroom.name, school_id: @classroom.school_id, year_id: @classroom.year_id}}
    assert_redirected_to classroom_url(@classroom)
  end

  # TODO: would need dependent destroy on user
  # test "should destroy classroom" do
  #   assert_difference("Classroom.count", -1) do
  #     delete classroom_url(@classroom)
  #   end

  #   assert_redirected_to classrooms_url
  # end
end
