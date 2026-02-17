# frozen_string_literal: true

require "test_helper"

module Admin
  module V2
    class ClassroomsControllerTest < ActionDispatch::IntegrationTest
      test "index" do
        classroom1 = create(:classroom, name: "Bravo")
        classroom2 = create(:classroom, name: "Charlie")
        classroom3 = create(:classroom, name: "Alpha")
        admin = create(:admin, admin: true, classroom: nil)
        sign_in(admin)

        get admin_v2_classrooms_path
        rows = css_select("tbody tr[id^='classroom_']")
        ordered_row_ids = rows.pluck("id")

        assert_response :success
        assert_select "h3", "Classrooms"
        assert_equal(
          [dom_id(classroom3), dom_id(classroom1), dom_id(classroom2)],
          ordered_row_ids
        )
      end

      test "show" do
        grade9 = create(:grade, level: 9)
        grade10 = create(:grade, level: 10)
        classroom = create(:classroom, grades: [grade9, grade10])
        admin = create(:admin, admin: true, classroom: nil)
        sign_in(admin)

        get admin_v2_classroom_path(classroom)

        assert_response :success
        assert_select "h2", classroom.name
        assert_select "[data-testid='grades_display'] dd", text: "9th-10th"
      end

      test "should get new" do
        admin = create(:admin, admin: true, classroom: nil)
        sign_in(admin)

        get new_admin_v2_classroom_path

        assert_response :success
        assert_select "h1", "New Classroom"
      end

      test "create" do
        grade = create(:grade, level: 7)
        school_year = create(:school_year)
        params = {
          classroom: {
            name: "Abc123",
            grade_ids: [grade.id],
            school_year_id: school_year.id
          }
        }
        admin = create(:admin, admin: true, classroom: nil)
        sign_in(admin)

        assert_difference("Classroom.count") do
          post(admin_v2_classrooms_path, params:)
        end

        assert_redirected_to admin_v2_classroom_path(Classroom.last)
        assert_equal "Classroom created successfully.", flash[:notice]
      end

      test "create with invalid params" do
        params = { classroom: { name: "" } }
        admin = create(:admin, admin: true, classroom: nil)
        sign_in(admin)

        assert_no_difference("Classroom.count") do
          post(admin_v2_classrooms_path, params:)
        end

        assert_response :unprocessable_entity
      end

      test "edit" do
        classroom = create(:classroom)
        admin = create(:admin, admin: true, classroom: nil)
        sign_in(admin)

        get edit_admin_v2_classroom_path(classroom)

        assert_response :success
        assert_select "h1", "Edit Classroom"
      end

      test "update" do
        name = "Abc123"
        classroom = create(:classroom)
        params = { classroom: { name: } }
        admin = create(:admin, admin: true, classroom: nil)
        sign_in(admin)

        patch(admin_v2_classroom_path(classroom), params:)

        assert_redirected_to admin_v2_classroom_path(classroom)
        assert_equal "Classroom updated successfully.", flash[:notice]
        assert_equal name, classroom.reload.name
      end

      test "update with invalid params" do
        classroom = create(:classroom)
        params = { classroom: { name: "" } }
        admin = create(:admin, admin: true, classroom: nil)
        sign_in(admin)

        patch(admin_v2_classroom_path(classroom), params:)

        assert_response :unprocessable_entity
      end

      test "toggle_archive" do
        classroom = create(:classroom, archived: false)
        admin = create(:admin, admin: true, classroom: nil)
        sign_in(admin)

        patch toggle_archive_admin_v2_classroom_path(classroom)
        classroom.reload

        assert_redirected_to admin_v2_classroom_path(classroom)
        assert_equal "Classroom has been archived.", flash[:notice]
        assert classroom.archived?
      end

      test "activate via toggle_archive" do
        classroom = create(:classroom, archived: true)
        admin = create(:admin, admin: true, classroom: nil)
        sign_in(admin)

        patch toggle_archive_admin_v2_classroom_path(classroom)
        classroom.reload

        assert_redirected_to admin_v2_classroom_path(classroom)
        assert_equal "Classroom has been activated.", flash[:notice]
        assert_not classroom.archived?
      end

      test "index when teacher" do
        teacher = create(:teacher)
        sign_in(teacher)

        get admin_v2_classrooms_path

        assert_redirected_to root_path
        assert_equal "Access denied. Admin privileges required.", flash[:alert]
      end

      test "toggle archive when teacher" do
        classroom = create(:classroom)
        teacher = create(:teacher)
        sign_in(teacher)

        patch toggle_archive_admin_v2_classroom_path(classroom)

        assert_redirected_to root_path
      end
    end
  end
end
