# frozen_string_literal: true

require "test_helper"

module Admin
  class GradesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin)
      sign_in(@admin)
    end

    test "index" do
      get admin_grades_path
      assert_response :success
    end

    test "new" do
      get new_admin_grade_path
      assert_response :success
    end

    test "show" do
      grade = create(:grade)
      get admin_grade_path(grade)
      assert_response :success
    end

    test "edit" do
      grade = create(:grade)
      get edit_admin_grade_path(grade)
      assert_response :success
    end

    test "create with valid params" do
      params = {
        grade: {
          level: 5,
          name: "Grade 5"
        }
      }

      assert_difference "Grade.count", 1 do
        post admin_grades_path, params: params
      end

      grade = Grade.last
      assert_redirected_to admin_grade_path(grade)
      assert_equal "Grade 5", grade.name
    end

    test "create with invalid params renders unprocessable_entity" do
      params = {
        grade: { name: "" }
      }

      assert_no_difference "Grade.count" do
        post admin_grades_path, params: params
      end

      assert_response :unprocessable_entity
    end

    test "update" do
      grade = create(:grade, name: "Old Name")

      params = {
        grade: { name: "New Name" }
      }

      patch admin_grade_path(grade), params: params

      assert_redirected_to admin_grade_path(grade)
      assert_equal "New Name", grade.reload.name
    end
  end
end
