# frozen_string_literal: true

require "test_helper"

module Admin
  # The empty state on admin index pages was copy-pasted into five templates,
  # none of which offered a way to create the first record - the copy said
  # "create your first X" and then left the admin to find the button. These tests
  # cover the shared partial that replaced them, including the call to action.
  class EmptyStatesTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin, admin: true, classroom: nil)
      sign_in(@admin)
    end

    test "school years index shows an empty state with a call to action" do
      assert_equal 0, SchoolYear.count, "expected no school years for this test"

      get admin_school_years_path

      assert_response :success
      assert_select "p", text: "No school years yet"
      assert_select "a[href=?]", new_admin_school_year_path, text: "New school year"
    end

    test "classrooms index shows an empty state with a call to action" do
      assert_equal 0, Classroom.count, "expected no classrooms for this test"

      get admin_classrooms_path

      assert_response :success
      assert_select "p", text: "No classrooms yet"
      assert_select "a[href=?]", new_admin_classroom_path, text: "New classroom"
    end

    test "teachers index shows an empty state with a call to action" do
      assert_equal 0, User.teachers.count, "expected no teachers for this test"

      get admin_teachers_path

      assert_response :success
      assert_select "p", text: "No teachers yet"
      assert_select "a[href=?]", new_admin_teacher_path, text: "New teacher"
    end

    test "students index shows an empty state with a call to action" do
      assert_equal 0, User.students.count, "expected no students for this test"

      get admin_students_path

      assert_response :success
      assert_select "p", text: "No students yet"
      assert_select "a[href=?]", new_admin_student_path, text: "New student"
    end
  end
end
