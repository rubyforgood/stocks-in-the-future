# frozen_string_literal: true

require "test_helper"

class StudentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @classroom = create(:classroom)
    @teacher = create(:teacher, classroom: @classroom)
    @student = create(:student, classroom: @classroom)
    @other_classroom = create(:classroom)
    @other_student = create(:student, classroom: @other_classroom)
  end

  test "requires teacher authentication" do
    get classroom_student_path(@classroom, @student)
    assert_redirected_to new_user_session_path
  end

  test "students cannot access student management actions" do
    sign_in @student

    get classroom_student_path(@classroom, @student)
    assert_redirected_to @student.portfolio_path

    get new_classroom_student_path(@classroom)
    assert_redirected_to @student.portfolio_path

    get edit_classroom_student_path(@classroom, @student)
    assert_redirected_to @student.portfolio_path

    patch classroom_student_path(@classroom, @student), params: { student: { username: "hacked" } }
    assert_redirected_to @student.portfolio_path

    assert_no_difference("User.kept.count") do
      delete classroom_student_path(@classroom, @student)
    end
    assert_redirected_to @student.portfolio_path
  end

  test "teachers can access their classroom students" do
    sign_in @teacher

    get classroom_student_path(@classroom, @student)
    assert_response :success
  end

  test "teacher can create student in their classroom" do
    sign_in @teacher

    assert_difference("User.count") do
      assert_difference("Student.count") do
        post classroom_students_path(@classroom), params: {
          student: {
            username: "newstudent",
            email: "newstudent@example.com"
          }
        }
      end
    end

    student = Student.last
    assert_equal @classroom, student.classroom
    assert_not_nil student.encrypted_password
    assert_redirected_to classroom_path(@classroom)
    assert_match(/created successfully/, flash[:notice])
  end

  test "student creation creates portfolio automatically" do
    sign_in @teacher

    assert_difference("Portfolio.count") do
      post classroom_students_path(@classroom), params: {
        student: {
          username: "newstudent",
          email: "newstudent@example.com"
        }
      }
    end

    student = Student.last
    assert_not_nil student.portfolio
    assert_equal 0, student.portfolio.current_position
  end

  test "student creation generates memorable password" do
    sign_in @teacher

    post classroom_students_path(@classroom), params: {
      student: {
        username: "newstudent",
        email: "newstudent@example.com"
      }
    }

    assert_match(/password:/, flash[:notice].downcase)
  end

  test "teacher can update student in their classroom" do
    sign_in @teacher

    patch classroom_student_path(@classroom, @student), params: {
      student: {
        username: "updatedname",
        email: "updated@example.com"
      }
    }

    @student.reload
    assert_equal "updatedname", @student.username
    assert_equal "updated@example.com", @student.email
    assert_redirected_to classroom_path(@classroom)
  end

  test "teacher can delete student from their classroom" do
    sign_in @teacher

    assert_difference("User.kept.count", -1) do
      delete classroom_student_path(@classroom, @student)
    end

    assert_redirected_to classroom_path(@classroom)
    assert_match(/deleted successfully/, flash[:notice])
    assert @student.reload.discarded?
  end

  test "teacher can reset student password" do
    sign_in @teacher
    original_password = @student.encrypted_password

    patch reset_password_classroom_student_path(@classroom, @student)

    @student.reload
    assert_not_equal original_password, @student.encrypted_password
    assert_redirected_to classroom_path(@classroom)
    assert_match(/password reset/i, flash[:notice])
    assert_match(/new password:/i, flash[:notice])
  end

  test "password reset generates memorable password" do
    sign_in @teacher

    patch reset_password_classroom_student_path(@classroom, @student)

    assert_match(/new password: \w+\d+/i, flash[:notice])
  end

  test "teacher can view student details" do
    create(:portfolio, user: @student, current_position: 8500.0)
    stock = create(:stock)
    create(:portfolio_stock, portfolio: @student.portfolio, stock: stock, shares: 10)
    create(:order, action: :sell, user: @student, stock: stock, shares: 1)

    sign_in @teacher
    get classroom_student_path(@classroom, @student)

    assert_response :success
    assert_includes response.body, @student.username
  end

  test "student show displays portfolio information" do
    create(:portfolio_transaction, portfolio: @student.portfolio, amount_cents: 100_000, transaction_type: "deposit")

    sign_in @teacher
    get classroom_student_path(@classroom, @student)

    assert_response :success
    assert_includes response.body, "1,000"
  end

  test "handles student with no portfolio gracefully" do
    student_no_portfolio = create(:student, classroom: @classroom)

    sign_in @teacher
    get classroom_student_path(@classroom, student_no_portfolio)

    assert_response :success
  end

  test "teacher is redirected when accessing discarded student" do
    sign_in @teacher
    @student.discard

    get classroom_student_path(@classroom, @student)

    assert_redirected_to classroom_path(@classroom)
    assert_match(/not found/i, flash[:alert])
  end
end
