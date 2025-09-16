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
  end
end
