# frozen_string_literal: true

require "test_helper"

module AdminV2
  class StudentsControllerTest < ActionDispatch::IntegrationTest
    test "index" do
      create(:student)
      create(:student)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_students_path

      assert_response :success
      assert_select "h3", "Students"
      assert_select "tbody tr", count: 2
    end

    test "index with discarded filter" do
      student = create(:student, :discarded)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_students_path(discarded: true)

      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "form[action=?]", restore_admin_v2_student_path(student) do
        assert_select "button", text: "Restore"
      end
    end

    test "index with all filter" do
      create(:student)
      create(:student)
      create(:student, :discarded)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_students_path(all: true)

      assert_response :success
      assert_select "tbody tr", count: 3
      assert_select "a[href*='edit']", count: 2
    end

    test "show" do
      username = "finn"
      student = create(:student, username:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_student_path(student)

      assert_response :success
      assert_select "h2", username
      assert_select "h3", text: "Portfolio Details"
      assert_select(
        "[data-testid='cash_balance_label']",
        text: "Cash Balance"
      )
      assert_select(
        "[data-testid='total_portfolio_worth_label']",
        text: "Total Portfolio Worth"
      )
    end

    test "new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_v2_student_path

      assert_response :success
      assert_select "h1", "New Student"
    end

    test "create" do
      username = "jake"
      classroom = create(:classroom, name: "Ice Kingdom")
      params = {
        student: {
          username:,
          classroom_id: classroom.id,
          password: "password123",
          password_confirmation: "password123"
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference(["Student.count", "Portfolio.count"]) do
        post(admin_v2_students_path, params:)
      end
      student = Student.last

      assert_redirected_to admin_v2_student_path(student)
      assert_equal(
        "Student #{username} created successfully. Password: password123",
        flash[:notice]
      )
      assert_not_nil student.portfolio
    end

    test "create with invalid params" do
      params = { student: { username: "", classroom_id: nil } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("Student.count") do
        post(admin_v2_students_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "edit" do
      student = create(:student)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_v2_student_path(student)

      assert_response :success
      assert_select "h1", "Edit Student"
    end

    test "update" do
      username = "marceline"
      student = create(:student)
      params = { student: { username: } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_v2_student_path(student), params:)
      student.reload

      assert_redirected_to admin_v2_student_path(student)
      assert_equal "Student updated successfully.", flash[:notice]
      assert_equal username, student.username
    end

    test "update with invalid params" do
      student = create(:student)
      params = { student: { username: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_v2_student_path(student), params:)

      assert_response :unprocessable_content
    end

    test "destroy" do
      username = "gunter"
      student = create(:student, username:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("Student.count") do
        delete admin_v2_student_path(student)
      end
      student.reload

      assert_redirected_to admin_v2_students_path
      assert_equal "Student #{username} discarded successfully.", flash[:notice]
      assert student.discarded?
    end

    test "restore" do
      username = "lsp"
      student = create(:student, :discarded, username:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch restore_admin_v2_student_path(student)
      student.reload

      assert_redirected_to admin_v2_students_path(discarded: true)
      assert_equal "Student #{username} restored successfully.", flash[:notice]
      assert_not student.discarded?
    end

    test "add_transaction" do
      portfolio = build(:portfolio, user: nil)
      student = create(:student, portfolio:)
      create(:portfolio_transaction, :deposit, portfolio:, amount_cents: 10_000)
      params = {
        student: {
          transaction_type: "deposit",
          add_fund_amount: "100.50",
          transaction_reason: "awards",
          transaction_description: "Test deposit"
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      post(add_transaction_admin_v2_student_path(student), params:)
      portfolio.reload

      assert_redirected_to admin_v2_student_path(student)
      assert_equal "Transaction added successfully.", flash[:notice]
      assert_equal 20_050, portfolio.cash_balance * 100
    end

    test "add_transaction debit" do
      student = create(:student)
      params = {
        student: {
          transaction_type: "debit",
          add_fund_amount: "50.25",
          transaction_reason: "administrative_adjustments",
          transaction_description: "Test debit"
        }
      }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      post(add_transaction_admin_v2_student_path(student), params:)
      transaction = student.portfolio.portfolio_transactions.last

      assert_redirected_to admin_v2_student_path(student)
      assert_equal "debit", transaction.transaction_type
      assert_equal 5_025, transaction.amount_cents
    end

    test "add_transaction invalid params" do
      student = create(:student)
      params = { student: { transaction_type: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      post(add_transaction_admin_v2_student_path(student), params:)
      expected_error_message =
        "Transaction Type must be present, Amount must be present, " \
        "Reason must be present"

      assert_redirected_to edit_admin_v2_student_path(student)
      assert_equal expected_error_message, flash[:alert]
    end
  end
end
