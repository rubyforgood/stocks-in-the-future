# frozen_string_literal: true

require "test_helper"

module Admin
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

    test "create" do
      admin = create(:admin)
      classroom = create(:classroom)
      sign_in(admin)

      teacher_params = {
        email: "newteacher@example.com",
        name: "New Teacher",
        username: "newteacher1",
        classroom_id: classroom.id
      }

      assert_difference("Teacher.count") do
        post admin_teachers_path, params: { teacher: teacher_params }
      end

      teacher = Teacher.order(created_at: :desc).first
      assert_equal "newteacher@example.com", teacher.email
      assert_equal "New Teacher", teacher.name
      assert_equal "newteacher1", teacher.username
      assert_includes teacher.classrooms, classroom

      assert_redirected_to admin_teachers_path
      assert_match I18n.t("teachers.create.notice"), flash[:notice]
    end
  end
end
