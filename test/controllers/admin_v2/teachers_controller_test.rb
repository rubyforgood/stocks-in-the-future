# frozen_string_literal: true

require "test_helper"

module AdminV2
  class TeachersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin, admin: true)
      sign_in(@admin)

      @classroom1 = create(:classroom, name: "Math 101")
      @classroom2 = create(:classroom, name: "Science 202")

      @teacher1 = create(:teacher, username: "teacher1", email: "teacher1@example.com")
      @teacher2 = create(:teacher, username: "teacher2", email: "teacher2@example.com")

      @teacher1.classrooms << @classroom1
    end

    # Index tests
    test "should get index" do
      get admin_v2_teachers_path

      assert_response :success
      assert_select "h3", "Teachers"
    end

    test "index sorts by username by default" do
      get admin_v2_teachers_path

      assert_response :success
      # Default sort should be by username ascending
      assert_select "tbody tr:nth-child(1)", text: /teacher1/
      assert_select "tbody tr:nth-child(2)", text: /teacher2/
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
      assert_select "h3", "Classrooms"
      assert_select "li", text: @classroom1.name
    end

    test "should show no classrooms message when teacher has no classrooms" do
      get admin_v2_teacher_path(@teacher2)

      assert_response :success
      assert_select "p", text: "No classrooms assigned to this teacher yet."
    end

    # New tests
    test "should get new" do
      get new_admin_v2_teacher_path

      assert_response :success
      assert_select "h1", "New Teacher"
    end

    # Create tests
    test "should create teacher" do
      assert_difference("Teacher.count") do
        post admin_v2_teachers_path, params: {
          teacher: {
            username: "newteacher",
            email: "newteacher@example.com",
            name: "New Teacher"
          }
        }
      end

      assert_redirected_to admin_v2_teacher_path(Teacher.last)
      assert_equal "Teacher created successfully. Password reset email has been sent.", flash[:notice]
    end

    test "should create teacher with classroom associations" do
      skip
      assert_difference("Teacher.count") do
        post admin_v2_teachers_path, params: {
          teacher: {
            username: "newteacher",
            email: "newteacher@example.com",
            name: "New Teacher",
            classroom_ids: [@classroom1.id, @classroom2.id]
          }
        }
      end

      teacher = Teacher.last
      assert_equal 2, teacher.classrooms.count
      assert_includes teacher.classrooms, @classroom1
      assert_includes teacher.classrooms, @classroom2
    end

    test "should send password reset email when creating teacher" do
      assert_difference("Teacher.count") do
        post admin_v2_teachers_path, params: {
          teacher: {
            username: "newteacher",
            email: "newteacher@example.com",
            name: "New Teacher"
          }
        }
      end

      # Check that password reset was called (this assumes Devise is configured properly)
      teacher = Teacher.last
      assert_not_nil teacher.reset_password_token
    end

    test "should not create teacher with invalid params" do
      assert_no_difference("Teacher.count") do
        post admin_v2_teachers_path, params: {
          teacher: {
            username: "",
            email: "invalid"
          }
        }
      end

      assert_response :unprocessable_content
    end

    # Edit tests
    test "should get edit" do
      get edit_admin_v2_teacher_path(@teacher1)

      assert_response :success
      assert_select "h1", "Edit Teacher"
    end

    # Update tests
    test "should update teacher" do
      patch admin_v2_teacher_path(@teacher1), params: {
        teacher: {
          name: "Updated Name"
        }
      }

      assert_redirected_to admin_v2_teacher_path(@teacher1)
      assert_equal "Teacher updated successfully.", flash[:notice]
      assert_equal "Updated Name", @teacher1.reload.name
    end

    test "should update teacher classroom associations" do
      skip patch admin_v2_teacher_path(@teacher1), params: {
        teacher: {
          classroom_ids: [@classroom2.id]
        }
      }

      assert_redirected_to admin_v2_teacher_path(@teacher1)
      @teacher1.reload
      assert_equal 1, @teacher1.classrooms.count
      assert_includes @teacher1.classrooms, @classroom2
      assert_not_includes @teacher1.classrooms, @classroom1
    end

    test "should not update teacher with invalid params" do
      patch admin_v2_teacher_path(@teacher1), params: {
        teacher: {
          username: ""
        }
      }

      assert_response :unprocessable_content
    end

    # Destroy tests
    test "should destroy teacher" do
      skip
      # assert_difference("Teacher.count", -1) do
      #   delete admin_v2_teacher_path(@teacher1)
      # end

      # assert_redirected_to admin_v2_teachers_path
      # assert_equal "Teacher deleted successfully.", flash[:notice]
    end

    # Authorization tests
    test "non-admin cannot access index" do
      sign_out(@admin)
      student = User.create!(username: "student", type: "Student", password: "password", classroom: @classroom1)
      sign_in(student)

      get admin_v2_teachers_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "non-admin cannot create teacher" do
      sign_out(@admin)
      student = User.create!(username: "student", type: "Student", password: "password", classroom: @classroom1)
      sign_in(student)

      post admin_v2_teachers_path, params: {
        teacher: {
          username: "newteacher",
          email: "newteacher@example.com"
        }
      }

      assert_redirected_to root_path
    end
  end
end
