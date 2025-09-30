# frozen_string_literal: true

require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "after_sign_in_path_for redirects students to root" do
    student = create(:student, username: "teststudent", password: "password123")

    post user_session_path, params: {
      user: { username: "teststudent", password: "password123" }
    }

    assert_redirected_to root_path
  end

  test "after_sign_in_path_for redirects teachers to root" do
    create(:teacher, username: "testteacher", password: "password123")

    post user_session_path, params: {
      user: { username: "testteacher", password: "password123" }
    }

    assert_redirected_to root_path
  end

  test "after_sign_in_path_for redirects admins to root" do
    create(:admin, username: "testadmin", password: "password123")

    post user_session_path, params: {
      user: { username: "testadmin", password: "password123" }
    }

    assert_redirected_to root_path
  end

  test "ensure_teacher_or_admin allows teachers" do
    teacher = create(:teacher)
    sign_in teacher

    get classrooms_path
    assert_response :success
  end

  test "ensure_teacher_or_admin allows admins" do
    admin = create(:admin)
    sign_in admin

    get classrooms_path
    assert_response :success
  end

  test "ensure_teacher_or_admin blocks students" do
    student = create(:student)
    sign_in student

    get new_classroom_path
    assert_redirected_to student.portfolio_path
  end
end
