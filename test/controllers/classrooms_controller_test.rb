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
  # Student Management Tests
  test "show includes student management for teachers" do
    classroom = create(:classroom)
    teacher = create(:teacher, classroom: classroom)
    student = create(:student, classroom: classroom)
    create(:portfolio, user: student)

    sign_in teacher
    get classroom_path(classroom)

    assert_response :success
    assert_includes response.body, student.username
  end

  test "teachers can only see their own classroom in index" do
    classroom1 = create(:classroom, name: "Teacher 1 Class")
    classroom2 = create(:classroom, name: "Teacher 2 Class")
    teacher = create(:teacher, classroom: classroom1)

    sign_in teacher
    get classrooms_path

    assert_response :success
    assert_includes response.body, classroom1.name
    assert_not_includes response.body, classroom2.name
  end

  test "admins can see all classrooms in index" do
    classroom1 = create(:classroom, name: "Class 1")
    classroom2 = create(:classroom, name: "Class 2")
    admin = create(:admin)

    sign_in admin
    get classrooms_path

    assert_response :success
    assert_includes response.body, classroom1.name
    assert_includes response.body, classroom2.name
  end

  test "students cannot create classrooms" do
    student = create(:student)
    sign_in student

    get new_classroom_path
    assert_redirected_to root_path
  end

  test "students cannot edit classrooms" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)
    sign_in student

    get edit_classroom_path(classroom)
    assert_redirected_to root_path
  end

  test "students cannot delete classrooms" do
    classroom = create(:classroom)
    student = create(:student, classroom: classroom)
    sign_in student

    assert_no_difference("Classroom.count") do
      delete classroom_path(classroom)
    end

    assert_redirected_to root_path
  end
end
