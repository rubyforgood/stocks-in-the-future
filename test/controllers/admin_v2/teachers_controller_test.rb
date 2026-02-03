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

    test "index sorts by username by default" do
      get admin_v2_teachers_path

      assert_response :success
      # Default sort should be by username ascending
      assert_select "tbody tr:nth-child(1)", text: /teacher1/
      assert_select "tbody tr:nth-child(2)", text: /teacher2/
    end

    test "index shows only active teachers by default" do
      @teacher1.discard

      get admin_v2_teachers_path

      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "span.bg-green-50", text: "Active"
    end

    test "index shows both active and deactivated teachers with all filter" do
      @teacher1.discard

      get admin_v2_teachers_path(all: true)

      assert_response :success
      assert_select "tbody tr", count: 2
      assert_select "span.bg-red-50", text: "Deactivated"
      assert_select "span.bg-green-50", text: "Active"
    end

    test "index shows only deactivated teachers with discarded filter" do
      @teacher1.discard

      get admin_v2_teachers_path(discarded: true)

      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "span.bg-red-50", text: "Deactivated"
    end

    # Show tests
    test "should show teacher" do
      get admin_v2_teacher_path(@teacher1)

      assert_response :success
      assert_select "h2", @teacher1.username
    end

    test "should show teacher classrooms" do
      get admin_v2_teacher_path(@teacher1)

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

    # Hard delete (destroy) tests
    test "should permanently delete deactivated teacher" do
      @teacher1.discard

      assert_difference("Teacher.with_discarded.count", -1) do
        delete admin_v2_teacher_path(@teacher1)
      end

      assert_redirected_to admin_v2_teachers_path
      assert_equal "Teacher teacher1 permanently deleted.", flash[:notice]
      assert_nil Teacher.with_discarded.find_by(id: @teacher1.id)
    end

    test "should not permanently delete active teacher" do
      assert_no_difference("Teacher.with_discarded.count") do
        delete admin_v2_teacher_path(@teacher1)
      end

      assert_redirected_to edit_admin_v2_teacher_path(@teacher1)
      assert_equal "Teacher must be deactivated before permanent deletion.", flash[:alert]
      assert_not @teacher1.reload.discarded?
    end

    test "permanent delete should remove teacher from database" do
      @teacher1.discard
      teacher_id = @teacher1.id

      delete admin_v2_teacher_path(@teacher1)

      # Teacher should be completely removed from database
      assert_raises(ActiveRecord::RecordNotFound) do
        Teacher.with_discarded.find(teacher_id)
      end
    end
  end
end
