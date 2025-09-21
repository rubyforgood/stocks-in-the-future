# frozen_string_literal: true

require "test_helper"

class TeachersControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    admin = create(:admin)
    sign_in(admin)

    get admin_teachers_path

    assert_response :success
  end

  test "new" do
    admin = create(:admin)
    sign_in(admin)

    get new_admin_teacher_path

    assert_response :success
  end

  test "show" do
    teacher = create(:teacher)
    admin = create(:admin)
    sign_in(admin)

    get admin_teacher_path(teacher)

    assert_response :success
  end

  test "edit" do
    teacher = create(:teacher)
    admin = create(:admin)
    sign_in(admin)

    get edit_admin_teacher_path(teacher)

    assert_response :success
  end

  test "update" do
    teacher = create(:teacher)
    admin = create(:admin)
    sign_in(admin)

    params = { teacher: { name: "Jane Smith" } }
    assert_changes "teacher.reload.updated_at" do
      patch admin_teacher_path(teacher), params: params
    end

    assert_redirected_to admin_teacher_path(teacher)
  end

  test "create creates a teacher, associates classroom, sends reset email, and redirects with notice" do
    admin = create(:admin)
    classroom = create(:classroom)
    sign_in(admin)
    ActionMailer::Base.deliveries.clear

    params = {
      teacher: {
        email: "t1@example.com",
        username: "teacher1",
        classroom_id: classroom.id
      }
    }

    assert_difference %w[Teacher.count ActionMailer::Base.deliveries.size], 1 do
      post admin_teachers_path, params: params
    end

    assert_redirected_to admin_teachers_path
    assert_not_nil flash[:notice]

    teacher = Teacher.find_by!(email: "t1@example.com")
    assert_includes teacher.classrooms, classroom

    teacher.reload

    assert_not_nil teacher.reset_password_sent_at, "reset_password_instructions should be sent"
    assert teacher.encrypted_password.present?, "temp password should be set"
  end

  test "create with non-existent classroom_id still creates teacher, sets alert, and does not associate classroom" do
    admin = create(:admin)
    sign_in(admin)
    ActionMailer::Base.deliveries.clear

    params = {
      teacher: {
        email: "t2@example.com",
        username: "teacher2"
      }
    }

    assert_difference %w[Teacher.count ActionMailer::Base.deliveries.size], 1 do
      post admin_teachers_path, params: params
    end

    assert_redirected_to admin_teachers_path
    assert_not_nil flash[:alert], "should show alert about invalid classroom"

    teacher = Teacher.find_by!(email: "t2@example.com")
    assert_equal 0, teacher.classrooms.count, "no classroom should be associated"
  end

  # ... existing code ...
  test "create with invalid params renders unprocessable_entity and does not create teacher" do
    admin = create(:admin)
    sign_in(admin)

    params = {
      teacher: {
        email: "", # invalid
        username: "" # invalid
        # classroom_id omitted
      }
    }

    assert_no_difference "Teacher.count" do
      post admin_teachers_path, params: params
    end

    assert_response :unprocessable_entity
  end
end
