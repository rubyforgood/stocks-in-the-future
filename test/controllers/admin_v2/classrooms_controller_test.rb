# frozen_string_literal: true

require "test_helper"

module Admin
  module V2
    class ClassroomsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin = create(:admin, admin: true)
        sign_in(@admin)

        school_year = create(:school_year)
        @classroom1 = create(:classroom, name: "Math 101", grade: 9, school_year: school_year)
        @classroom2 = create(:classroom, name: "Science 202", grade: 10, school_year: school_year)
        @classroom3 = create(:classroom, name: "History 303", grade: 11, school_year: school_year, archived: true)
      end

      # Index tests
      test "should get index" do
        get admin_v2_classrooms_path

        assert_response :success
        assert_select "h3", "Classrooms"
      end

      test "index sorts by name by default" do
        get admin_v2_classrooms_path

        assert_response :success
        # Check order in response (name ascending: H, M, S)
        assert_select "tbody tr:nth-child(1)", text: /History 303/
        assert_select "tbody tr:nth-child(2)", text: /Math 101/
        assert_select "tbody tr:nth-child(3)", text: /Science 202/
      end

      test "index sorts by grade when specified" do
        get admin_v2_classrooms_path, params: { sort: "grade", direction: "asc" }

        assert_response :success
        # Check order in response (grade ascending: 9, 10, 11)
        assert_select "tbody tr:nth-child(1)", text: /Math 101/
        assert_select "tbody tr:nth-child(2)", text: /Science 202/
        assert_select "tbody tr:nth-child(3)", text: /History 303/
      end

      # Show tests
      test "should show classroom" do
        get admin_v2_classroom_path(@classroom1)

        assert_response :success
        assert_select "h2", @classroom1.name
      end

      # New tests
      test "should get new" do
        get new_admin_v2_classroom_path

        assert_response :success
        assert_select "h1", "New Classroom"
      end

      # Create tests
      test "should create classroom" do
        school_year = create(:school_year)
        assert_difference("Classroom.count") do
          post admin_v2_classrooms_path, params: {
            classroom: {
              name: "New Classroom",
              grade: 12,
              school_year_id: school_year.id,
              trading_enabled: true
            }
          }
        end

        assert_redirected_to admin_v2_classroom_path(Classroom.last)
        assert_equal "Classroom created successfully.", flash[:notice]
      end

      test "should not create classroom with invalid params" do
        assert_no_difference("Classroom.count") do
          post admin_v2_classrooms_path, params: { classroom: { name: "", grade: nil } }
        end

        assert_response :unprocessable_entity
      end

      # Edit tests
      test "should get edit" do
        get edit_admin_v2_classroom_path(@classroom1)

        assert_response :success
        assert_select "h1", "Edit Classroom"
      end

      # Update tests
      test "should update classroom" do
        patch admin_v2_classroom_path(@classroom1), params: { classroom: { name: "Updated Classroom" } }

        assert_redirected_to admin_v2_classroom_path(@classroom1)
        assert_equal "Classroom updated successfully.", flash[:notice]
        assert_equal "Updated Classroom", @classroom1.reload.name
      end

      test "should not update classroom with invalid params" do
        patch admin_v2_classroom_path(@classroom1), params: { classroom: { name: "" } }

        assert_response :unprocessable_entity
      end

      # Destroy tests
      test "should destroy classroom" do
        assert_difference("Classroom.count", -1) do
          delete admin_v2_classroom_path(@classroom1)
        end

        assert_redirected_to admin_v2_classrooms_path
        assert_equal "Classroom deleted successfully.", flash[:notice]
      end

      # Toggle Archive tests
      test "should archive classroom via toggle_archive" do
        assert_not @classroom1.archived?

        patch toggle_archive_admin_v2_classroom_path(@classroom1)

        @classroom1.reload
        assert @classroom1.archived?
        assert_redirected_to admin_v2_classroom_path(@classroom1)
        assert_equal "Classroom has been archived.", flash[:notice]
      end

      test "should activate classroom via toggle_archive" do
        assert @classroom3.archived?

        patch toggle_archive_admin_v2_classroom_path(@classroom3)

        @classroom3.reload
        assert_not @classroom3.archived?
        assert_redirected_to admin_v2_classroom_path(@classroom3)
        assert_equal "Classroom has been activated.", flash[:notice]
      end

      # Authorization tests
      test "non-admin cannot access index" do
        sign_out(@admin)
        teacher = create(:teacher)
        sign_in(teacher)

        get admin_v2_classrooms_path

        assert_redirected_to root_path
        assert_equal "Access denied. Admin privileges required.", flash[:alert]
      end

      test "non-admin cannot toggle archive classroom" do
        sign_out(@admin)
        teacher = create(:teacher)
        sign_in(teacher)

        patch toggle_archive_admin_v2_classroom_path(@classroom1)

        assert_response :redirect
        assert_redirected_to root_path
      end
    end
  end
end
