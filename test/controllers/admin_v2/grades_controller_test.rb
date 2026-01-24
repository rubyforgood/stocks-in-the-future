# frozen_string_literal: true

require "test_helper"

module AdminV2
  class GradesControllerTest < ActionDispatch::IntegrationTest
    test "index" do
      grade1 = create(:grade, level: 1)
      grade2 = create(:grade, level: 2)
      grade3 = create(:grade, level: 0)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_grades_path
      rows = css_select("tbody tr[id^='grade_']")
      row_ids = rows.pluck("id")

      assert_response :success
      assert_select "h3", "Grades"
      assert_equal(
        [dom_id(grade3), dom_id(grade1), dom_id(grade2)],
        row_ids
      )
    end

    test "show" do
      name = "Lumpy Space Level"
      grade = create(:grade, name:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_grade_path(grade)

      assert_response :success
      assert_select "h2", name
    end

    test "new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_v2_grade_path

      assert_response :success
      assert_select "h1", "New Grade"
    end

    test "create" do
      params = { grade: { level: 3, name: "Fire Kingdom Level" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("Grade.count") do
        post(admin_v2_grades_path, params:)
      end
      grade = Grade.last

      assert_redirected_to admin_v2_grade_path(grade)
      assert_equal "Grade created successfully.", flash[:notice]
    end

    test "create with invalid params" do
      params = { grade: { name: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("Grade.count") do
        post(admin_v2_grades_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "edit" do
      grade = create(:grade)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_v2_grade_path(grade)

      assert_response :success
      assert_select "h1", "Edit Grade"
    end

    test "update" do
      name = "Nightosphere Level"
      grade = create(:grade)
      params = { grade: { name: } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_v2_grade_path(grade), params:)
      grade.reload

      assert_redirected_to admin_v2_grade_path(grade)
      assert_equal "Grade updated successfully.", flash[:notice]
      assert_equal name, grade.name
    end

    test "update with invalid params" do
      grade = create(:grade)
      params = { grade: { name: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_v2_grade_path(grade), params:)

      assert_response :unprocessable_content
    end

    test "destroy" do
      grade = create(:grade)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("Grade.count", -1) do
        delete admin_v2_grade_path(grade)
      end

      assert_redirected_to admin_v2_grades_path
      assert_equal "Grade deleted successfully.", flash[:notice]
    end
  end
end
