require "test_helper"

class Admin::StudentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:one)
  end

  test "should update student email" do
    @student.update_attribute(:email, "nottest@nottest.com")

    patch admin_student_url(@student), params: {student: {email: "test@test.com"}}
    @student.reload
    assert_equal "test@test.com", @student.email
    assert_redirected_to admin_student_url(@student)
  end

  test "should not update with an error" do
    @student.update_attribute(:username, "testingusername")

    patch admin_student_url(@student), params: {student: {username: ""}}

    @student.reload

    assert_equal "testingusername", @student.username
    assert_response :unprocessable_entity
    assert_select "div#error_explanation"
  end

  test "given a add_fund_amount, creates a transaction" do
    assert_difference("PortfolioTransaction.count", 1) do
      patch admin_student_url(@student), params: {student: {add_fund_amount: "10.50"}}
    end

    transaction = PortfolioTransaction.last

    assert_equal "deposit", transaction.transaction_type
    assert_equal 10.50, transaction.amount
    assert_equal @student.reload.portfolio.portfolio_transactions.last, transaction

    assert_redirected_to admin_student_url(@student)
  end

  test "given an empty add_fund_amount, does not create a transaction" do
    assert_difference("PortfolioTransaction.count", 0) do
      patch admin_student_url(@student), params: {student: {add_fund_amount: ""}}
    end
  end
end
