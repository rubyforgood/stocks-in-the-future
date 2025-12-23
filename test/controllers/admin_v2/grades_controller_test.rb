# frozen_string_literal: true

require "test_helper"

module Admin
  module V2
    class GradesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:admin, admin: true)
        sign_in(@admin)

        @grade1 = create(:grade, name: "First Grade", level: 1)
        @grade2 = create(:grade, name: "Second Grade", level: 2)
        @grade3 = create(:grade, name: "Kindergarten", level: 0)
      end

      # Index tests
      test "should get index" do
        get admin_v2_grades_path

        assert_response :success
        assert_select "h3", "Grades"
      end

      test "index sorts by level by default" do
        get admin_v2_grades_path

        assert_response :success
        # Check order in response (level ascending: 0, 1, 2)
        assert_select "tbody tr:nth-child(1)", text: /Kindergarten/
        assert_select "tbody tr:nth-child(2)", text: /First Grade/
        assert_select "tbody tr:nth-child(3)", text: /Second Grade/
      end

      test "index sorts by name when specified" do
        get admin_v2_grades_path, params: { sort: "name", direction: "asc" }

        assert_response :success
        # Check order in response (name ascending: F, K, S)
        assert_select "tbody tr:nth-child(1)", text: /First Grade/
        assert_select "tbody tr:nth-child(2)", text: /Kindergarten/
        assert_select "tbody tr:nth-child(3)", text: /Second Grade/
      end

      test "index sorts descending when specified" do
        get admin_v2_grades_path, params: { sort: "level", direction: "desc" }

        assert_response :success
        # Check order in response (level descending: 2, 1, 0)
        assert_select "tbody tr:nth-child(1)", text: /Second Grade/
        assert_select "tbody tr:nth-child(2)", text: /First Grade/
        assert_select "tbody tr:nth-child(3)", text: /Kindergarten/
      end

      # Show tests
      test "should show grade" do
        get admin_v2_grade_path(@grade1)

        assert_response :success
        assert_select "h2", @grade1.name
      end

      # New tests
      test "should get new" do
        get new_admin_v2_grade_path

        assert_response :success
        assert_select "h1", "New Grade"
      end

      # Create tests
      test "should create grade" do
        assert_difference("Grade.count") do
          post admin_v2_grades_path, params: { grade: { name: "Third Grade", level: 3 } }
        end

        assert_redirected_to admin_v2_grade_path(Grade.last)
        assert_equal "Grade created successfully.", flash[:notice]
      end

      test "should not create grade with invalid params" do
        assert_no_difference("Grade.count") do
          post admin_v2_grades_path, params: { grade: { name: "", level: nil } }
        end

        assert_response :unprocessable_entity
      end

      # Edit tests
      test "should get edit" do
        get edit_admin_v2_grade_path(@grade1)

        assert_response :success
        assert_select "h1", "Edit Grade"
      end

      # Update tests
      test "should update grade" do
        patch admin_v2_grade_path(@grade1), params: { grade: { name: "Updated Grade" } }

        assert_redirected_to admin_v2_grade_path(@grade1)
        assert_equal "Grade updated successfully.", flash[:notice]
        assert_equal "Updated Grade", @grade1.reload.name
      end

      test "should not update grade with invalid params" do
        patch admin_v2_grade_path(@grade1), params: { grade: { name: "" } }

        assert_response :unprocessable_entity
      end

      # Destroy tests
      test "should destroy grade" do
        assert_difference("Grade.count", -1) do
          delete admin_v2_grade_path(@grade1)
        end

        assert_redirected_to admin_v2_grades_path
        assert_equal "Grade deleted successfully.", flash[:notice]
      end

      # Authorization tests
      test "non-admin cannot access index" do
        sign_out(@admin)
        teacher = create(:teacher)
        sign_in(teacher)

        get admin_v2_grades_path

        assert_redirected_to root_path
        assert_equal "Access denied. Admin privileges required.", flash[:alert]
      end
    end
  end
end
