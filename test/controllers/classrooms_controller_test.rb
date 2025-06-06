require "test_helper"

class ClassroomsControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    teacher = create(:teacher)
    sign_in(teacher)

    get classrooms_path

    assert_response :success
  end

  test "new" do
    teacher = create(:teacher)
    sign_in(teacher)

    get new_classroom_path

    assert_response :success
  end

  test "create" do
    params = {classroom: {school_name: "x", year_value: "1999"}}
    teacher = create(:teacher)
    sign_in(teacher)

    assert_difference("Classroom.count") do
      post(classrooms_path, params:)
    end

    assert_redirected_to classroom_path(Classroom.last)
    assert_equal t("classrooms.create.notice"), flash[:notice]
  end

  test "show" do
    classroom = create(:classroom)
    teacher = create(:teacher)
    sign_in(teacher)

    get classroom_path(classroom)

    assert_response :success
  end

  test "edit" do
    classroom = create(:classroom)
    teacher = create(:teacher)
    sign_in(teacher)

    get edit_classroom_path(classroom)

    assert_response :success
  end

  test "update" do
    params = {classroom: {name: "Abc123", year_value: "2000"}}
    classroom = create(:classroom)
    teacher = create(:teacher)
    sign_in(teacher)

    assert_changes "classroom.reload.updated_at" do
      patch(classroom_path(classroom), params:)
    end

    assert_redirected_to classroom_path(classroom)
    assert_equal t("classrooms.update.notice"), flash[:notice]
  end

  test "destroy" do
    classroom = create(:classroom)
    teacher = create(:teacher)
    sign_in(teacher)

    assert_difference("Classroom.count", -1) do
      delete classroom_path(classroom)
    end

    assert_redirected_to classrooms_path
    assert_equal t("classrooms.destroy.notice"), flash[:notice]
  end
end
