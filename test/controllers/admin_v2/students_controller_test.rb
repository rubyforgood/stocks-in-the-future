# frozen_string_literal: true

require "test_helper"

module AdminV2
  class StudentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin, admin: true)
      sign_in(@admin)

      @classroom1 = create(:classroom, name: "Math 101")
      @classroom2 = create(:classroom, name: "Science 202")

      @student1 = User.create!(username: "student1", type: "Student", password: "password", classroom: @classroom1)
      @student2 = User.create!(username: "student2", type: "Student", password: "password", classroom: @classroom2)
      @student3 = User.create!(username: "student3", type: "Student", password: "password", classroom: @classroom1)
      @student3.discard # Soft delete
    end

    # Index tests
    test "should get index" do
      get admin_v2_students_path

      assert_response :success
      assert_select "h3", "Students"
    end

    test "index shows only kept students by default" do
      get admin_v2_students_path

      assert_response :success
      # Should show student1 and student2, but not discarded student3
      assert_select "tbody tr", count: 2
    end

    test "index sorts by username by default" do
      get admin_v2_students_path

      assert_response :success
      # Default sort should be by username ascending
      assert_select "tbody tr:nth-child(1)", text: /student1/
      assert_select "tbody tr:nth-child(2)", text: /student2/
    end

    # Show tests
    test "should show student" do
      get admin_v2_student_path(@student1)

      assert_response :success
      assert_select "h2", @student1.username
    end

    test "should show student portfolio link" do
      get admin_v2_student_path(@student1)

      assert_response :success
      assert_select "a[href=?]", user_portfolio_path(@student1, @student1.portfolio), text: "View Portfolio"
    end

    # New tests
    test "should get new" do
      get new_admin_v2_student_path

      assert_response :success
      assert_select "h1", "New Student"
    end

    # Create tests
    test "should create student" do
      assert_difference("Student.count") do
        post admin_v2_students_path, params: {
          student: {
            username: "newstudent",
            classroom_id: @classroom1.id,
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      assert_redirected_to admin_v2_student_path(Student.last)
      assert_match(/Student newstudent created successfully/, flash[:notice])
    end

    test "should create student with auto-generated password when password is blank" do
      assert_difference("Student.count") do
        post admin_v2_students_path, params: {
          student: {
            username: "newstudent",
            classroom_id: @classroom1.id
          }
        }
      end

      assert_redirected_to admin_v2_student_path(Student.last)
      assert_match(/Password:/, flash[:notice])
    end

    test "should not create student with invalid params" do
      assert_no_difference("Student.count") do
        post admin_v2_students_path, params: {
          student: {
            username: "",
            classroom_id: nil
          }
        }
      end

      assert_response :unprocessable_content
    end

    test "should create portfolio for new student" do
      assert_difference(["Student.count", "Portfolio.count"]) do
        post admin_v2_students_path, params: {
          student: {
            username: "newstudent",
            classroom_id: @classroom1.id,
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      student = Student.last
      assert_not_nil student.portfolio
    end

    # Edit tests
    test "should get edit" do
      get edit_admin_v2_student_path(@student1)

      assert_response :success
      assert_select "h1", "Edit Student"
    end

    # Update tests
    test "should update student" do
      patch admin_v2_student_path(@student1), params: {
        student: {
          username: "updatedstudent"
        }
      }

      assert_redirected_to admin_v2_student_path(@student1)
      assert_equal "Student updated successfully.", flash[:notice]
      assert_equal "updatedstudent", @student1.reload.username
    end

    test "should not update student with invalid params" do
      patch admin_v2_student_path(@student1), params: {
        student: {
          username: ""
        }
      }

      assert_response :unprocessable_content
    end

    # Destroy tests
    test "should soft delete student" do
      assert_no_difference("Student.count") do
        delete admin_v2_student_path(@student1)
      end

      assert_redirected_to admin_v2_students_path
      assert_match(/Student student1 discarded successfully/, flash[:notice])
      assert @student1.reload.discarded?
    end

    # Restore tests
    test "should restore discarded student" do
      assert @student3.discarded?

      patch restore_admin_v2_student_path(@student3)

      assert_redirected_to admin_v2_students_path(discarded: true)
      assert_match(/Student student3 restored successfully/, flash[:notice])
      assert_not @student3.reload.discarded?
    end

    # Filter tests
    test "index with discarded filter shows only discarded students" do
      get admin_v2_students_path(discarded: true)

      assert_response :success
      # Should show only discarded student3
      assert_select "tbody tr", count: 1
      assert_select "tbody", text: /student3/
    end

    test "index with all filter shows all students including discarded" do
      get admin_v2_students_path(all: true)

      assert_response :success
      # Should show all 3 students (student1, student2, student3)
      assert_select "tbody tr", count: 3
    end

    test "index shows restore button for discarded students" do
      get admin_v2_students_path(discarded: true)

      assert_response :success
      assert_select "button[value=?]", restore_admin_v2_student_path(@student3), text: "Restore"
    end

    test "index shows discard button for active students" do
      get admin_v2_students_path

      assert_response :success
      assert_select "a[data-turbo-method='delete']", text: "Discard", count: 2
    end

    test "index hides edit button for discarded students" do
      get admin_v2_students_path(all: true)

      assert_response :success
      # Should have edit links for active students (2) but not for discarded student3
      assert_select "a[href*='edit']", count: 2
    end

    # Authorization tests
    test "non-admin cannot access index" do
      sign_out(@admin)
      teacher = create(:teacher)
      sign_in(teacher)

      get admin_v2_students_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "non-admin cannot create student" do
      sign_out(@admin)
      teacher = create(:teacher)
      sign_in(teacher)

      post admin_v2_students_path, params: {
        student: {
          username: "newstudent",
          classroom_id: @classroom1.id
        }
      }

      assert_redirected_to root_path
    end

    test "non-admin cannot restore student" do
      sign_out(@admin)
      teacher = create(:teacher)
      sign_in(teacher)

      patch restore_admin_v2_student_path(@student3)

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end
  end
end
