# frozen_string_literal: true

require "test_helper"

module Admin
  class StudentsControllerTest < ActionDispatch::IntegrationTest
    test "should update student email" do
      new_email = "abc123@example.com"
      admin = create(:admin)
      student = create(:student)
      sign_in(admin)

      assert_changes "student.reload.updated_at" do
        patch admin_student_path(student), params: { student: { email: new_email } }
      end

      assert_equal new_email, student.email
      assert_redirected_to admin_student_path(student)
    end

    test "should not update with an error" do
      username = "abc123"
      admin = create(:admin)
      student = create(:student, username:)
      sign_in(admin)

      assert_no_changes "student.reload.updated_at" do
        patch admin_student_path(student), params: { student: { username: "" } }
      end

      assert_equal username, student.username
      assert_response :unprocessable_content
      assert_select "div#error_explanation"
    end

    test "given a add_fund_amount, creates a transaction" do
      params = { student: {
        transaction_type: "deposit",
        add_fund_amount: 1_050,
        transaction_reason: :awards
      } }
      admin = create(:admin)
      student = create(:student)
      create(:portfolio, user: student)
      sign_in(admin)

      assert_difference("PortfolioTransaction.count", 1) do
        post(admin_student_add_transaction_path(student), params:)
      end

      transaction = PortfolioTransaction.last
      assert transaction.deposit?
      assert_equal 1_050, transaction.amount_cents
      assert_equal(
        student.reload.portfolio.portfolio_transactions.last,
        transaction
      )
      assert_redirected_to admin_student_path(student)
    end

    test "given an empty add_fund_amount, does not create a transaction" do
      params = { student: { add_fund_amount: "" } }
      admin = create(:admin)
      student = create(:student)
      create(:portfolio, user: student)
      sign_in(admin)

      assert_difference("PortfolioTransaction.count", 0) do
        patch(admin_student_path(student), params:)
      end

      assert_redirected_to admin_student_path(student)
    end

    test "add_transaction fails when transaction_type is missing" do
      params = { student: {
        add_fund_amount: 1_050,
        transaction_reason: :awards
      } }
      admin = create(:admin)
      student = create(:student)
      create(:portfolio, user: student)
      sign_in(admin)

      assert_no_difference("PortfolioTransaction.count") do
        post(admin_student_add_transaction_path(student), params:)
      end

      assert_redirected_to edit_admin_student_path(student)
      assert_equal "Transaction Type must be present", flash[:alert]
    end

    test "add_transaction fails when amount is missing" do
      params = { student: {
        transaction_type: "deposit",
        transaction_reason: :awards
      } }
      admin = create(:admin)
      student = create(:student)
      create(:portfolio, user: student)
      sign_in(admin)

      assert_no_difference("PortfolioTransaction.count") do
        post(admin_student_add_transaction_path(student), params:)
      end

      assert_redirected_to edit_admin_student_path(student)
      assert_equal "Amount must be present", flash[:alert]
    end

    test "add_transaction fails when reason is missing" do
      params = { student: {
        transaction_type: "deposit",
        add_fund_amount: 1_050
      } }
      admin = create(:admin)
      student = create(:student)
      create(:portfolio, user: student)
      sign_in(admin)

      assert_no_difference("PortfolioTransaction.count") do
        post(admin_student_add_transaction_path(student), params:)
      end

      assert_redirected_to edit_admin_student_path(student)
      assert_equal "Reason must be present", flash[:alert]
    end

    test "add_transaction fails when reason is missing even with description" do
      params = { student: {
        transaction_type: "deposit",
        add_fund_amount: 1_050,
        transaction_description: "Some notes about the transaction"
      } }
      admin = create(:admin)
      student = create(:student)
      create(:portfolio, user: student)
      sign_in(admin)

      assert_no_difference("PortfolioTransaction.count") do
        post(admin_student_add_transaction_path(student), params:)
      end

      assert_redirected_to edit_admin_student_path(student)
      assert_equal "Reason must be present", flash[:alert]
    end

    test "add_transaction stores transaction_description" do
      params = { student: {
        transaction_type: "deposit",
        add_fund_amount: 1_050,
        transaction_reason: :awards,
        transaction_description: "Extra credit for science fair"
      } }
      admin = create(:admin)
      student = create(:student)
      create(:portfolio, user: student)
      sign_in(admin)

      assert_difference("PortfolioTransaction.count", 1) do
        post(admin_student_add_transaction_path(student), params:)
      end

      transaction = PortfolioTransaction.last
      assert_equal "Extra credit for science fair", transaction.description
      assert_equal "awards", transaction.reason
    end

    test "add_transaction creates debit transaction" do
      params = { student: {
        transaction_type: "debit",
        add_fund_amount: 500,
        transaction_reason: :administrative_adjustments
      } }
      admin = create(:admin)
      student = create(:student)
      create(:portfolio, user: student)
      sign_in(admin)

      assert_difference("PortfolioTransaction.count", 1) do
        post(admin_student_add_transaction_path(student), params:)
      end

      transaction = PortfolioTransaction.last
      assert transaction.debit?
      assert_equal 500, transaction.amount_cents
    end

    test "import should redirect with success message for valid CSV" do
      admin = create(:admin)
      classroom = create(:classroom)
      sign_in(admin)

      csv_content = [
        "classroom_id,username",
        "#{classroom.id},test_student"
      ].join("\n")

      with_temp_csv_file(csv_content) do |csv_file|
        post import_admin_students_path, params: { csv_file: fixture_file_upload(csv_file.path, "text/csv") }

        assert_redirected_to admin_students_path
        assert_not_nil flash[:notice]
      end
    end

    test "import should redirect with alert when no file provided" do
      admin = create(:admin)
      sign_in(admin)

      post import_admin_students_path, params: {}

      assert_redirected_to admin_students_path
      assert_equal "Please select a CSV file", flash[:alert]
    end

    test "import should handle malformed CSV" do
      admin = create(:admin)
      sign_in(admin)

      csv_content = "classroom_id,username\n\"unclosed quote,invalid_row"

      with_temp_csv_file(csv_content) do |csv_file|
        post import_admin_students_path, params: { csv_file: fixture_file_upload(csv_file.path, "text/csv") }

        assert_redirected_to admin_students_path
        assert_match(/Invalid CSV format/, flash[:alert])
      end
    end

    test "import should handle empty CSV" do
      admin = create(:admin)
      sign_in(admin)

      csv_content = "classroom_id,username\n"

      with_temp_csv_file(csv_content) do |csv_file|
        post import_admin_students_path, params: { csv_file: fixture_file_upload(csv_file.path, "text/csv") }

        assert_redirected_to admin_students_path
        assert_equal "No students found in CSV file", flash[:alert]
      end
    end

    test "template should download CSV template file" do
      admin = create(:admin)
      sign_in(admin)

      get template_admin_students_path

      assert_response :success
      assert_equal "text/csv", response.content_type
      assert_match "attachment", response.headers["Content-Disposition"]
      assert_match "student_import_template.csv", response.headers["Content-Disposition"]
    end

    test "admin discards a student" do
      admin   = create(:admin)
      student = create(:student)
      sign_in admin

      assert_changes -> { student.reload.discarded? }, from: false, to: true do
        delete admin_student_path(student)
      end
      assert_redirected_to admin_students_path
    end

    test "admin restores a student" do
      admin   = create(:admin)
      student = create(:student)
      student.discard
      sign_in admin

      patch restore_admin_student_path(student)

      assert_redirected_to admin_students_path(discarded: 1)
      assert_not_predicate student.reload, :discarded?
    end
  end
end
