# frozen_string_literal: true

require 'test_helper'

module Admin
  class StudentsControllerTest < ActionDispatch::IntegrationTest
    test 'should update student email' do
      new_email = 'abc123@example.com'
      admin = create(:admin)
      student = create(:student)
      sign_in(admin)

      assert_changes 'student.reload.updated_at' do
        patch admin_student_path(student), params: { student: { email: new_email } }
      end

      assert_equal new_email, student.email
      assert_redirected_to admin_student_path(student)
    end

    test 'should not update with an error' do
      username = 'abc123'
      admin = create(:admin)
      student = create(:student, username:)
      sign_in(admin)

      assert_no_changes 'student.reload.updated_at' do
        patch admin_student_path(student), params: { student: { username: '' } }
      end

      assert_equal username, student.username
      assert_response :unprocessable_entity
      assert_select 'div#error_explanation'
    end

    test 'given a add_fund_amount, creates a transaction' do
      params = { student: { add_fund_amount: 1_050 } }
      admin = create(:admin)
      student = create(:student)
      create(:portfolio, user: student)
      sign_in(admin)

      assert_difference('PortfolioTransaction.count', 1) do
        patch(admin_student_path(student), params:)
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

    test 'given an empty add_fund_amount, does not create a transaction' do
      params = { student: { add_fund_amount: '' } }
      admin = create(:admin)
      student = create(:student)
      create(:portfolio, user: student)
      sign_in(admin)

      assert_difference('PortfolioTransaction.count', 0) do
        patch(admin_student_path(student), params:)
      end

      assert_redirected_to admin_student_path(student)
    end
  end
end
