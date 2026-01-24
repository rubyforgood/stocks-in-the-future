# frozen_string_literal: true

require "test_helper"

module AdminV2
  class TeachersControllerTest < ActionDispatch::IntegrationTest
    test "index" do
      teacher1 = create(:teacher, username: "marceline")
      teacher2 = create(:teacher, username: "lsp")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_teachers_path
      rows = css_select("tbody tr[id^='teacher_']")
      row_ids = rows.pluck("id")

      assert_response :success
      assert_select "h3", "Teachers"
      assert_equal [dom_id(teacher2), dom_id(teacher1)], row_ids
    end

    test "show" do
      username = "lsp"
      classroom_name = "Ice Kingdom"
      classroom = create(:classroom, name: classroom_name)
      teacher = create(:teacher, username:, classrooms: [classroom])
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_teacher_path(teacher)

      assert_response :success
      assert_select "h2", username
      assert_select "h3", "Classrooms"
      assert_select "li", text: classroom_name
    end

    test "show when teacher has no classrooms" do
      teacher = create(:teacher)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_teacher_path(teacher)

      assert_response :success
      assert_select "p", text: "No classrooms assigned to this teacher yet."
    end

    test "new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_v2_teacher_path

      assert_response :success
      assert_select "h1", "New Teacher"
    end

    test "create" do
      classroom1 = create(:classroom, name: "Ice Kingdom")
      classroom2 = create(:classroom, name: "Candy Kingdom")
      params = {
        teacher: {
          username: "lsp",
          email: "lsp@lumpyspace.com",
          name: "Lumpy Space Princess",
          classroom_ids: [classroom1.id, classroom2.id]
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("Teacher.count") do
        post(admin_v2_teachers_path, params:)
      end

      teacher = Teacher.last
      assert_redirected_to admin_v2_teacher_path(teacher)
      assert_equal(
        "Teacher created successfully. Password reset email has been sent.",
        flash[:notice]
      )
      assert_equal [classroom1, classroom2], teacher.classrooms
      assert_not_nil teacher.reset_password_token
    end

    test "create with invalid params" do
      params = {
        teacher: {
          username: "",
          email: "invalid"
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("Teacher.count") do
        post(admin_v2_teachers_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "edit" do
      teacher = create(:teacher)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_v2_teacher_path(teacher)

      assert_response :success
      assert_select "h1", "Edit Teacher"
    end

    test "update" do
      name = "Lumpy Space Princess"
      classroom1 = create(:classroom, name: "Ice Kingdom")
      classroom2 = create(:classroom, name: "Candy Kingdom")
      teacher = create(:teacher, classrooms: [classroom1])
      params = { teacher: { name:, classroom_ids: [classroom2.id] } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_v2_teacher_path(teacher), params:)
      teacher.reload

      assert_redirected_to admin_v2_teacher_path(teacher)
      assert_equal "Teacher updated successfully.", flash[:notice]
      assert_equal name, teacher.name
      assert_equal [classroom2], teacher.classrooms
    end

    test "update with invalid params" do
      teacher = create(:teacher)
      params = { teacher: { username: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_v2_teacher_path(teacher), params:)

      assert_response :unprocessable_content
    end

    test "destroy" do
      teacher = create(:teacher)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("Teacher.count") do
        delete admin_v2_teacher_path(teacher)
      end
      teacher.reload

      assert_redirected_to admin_v2_teachers_path
      assert_equal "Teacher deleted successfully.", flash[:notice]
      assert teacher.discarded?
    end
  end
end
