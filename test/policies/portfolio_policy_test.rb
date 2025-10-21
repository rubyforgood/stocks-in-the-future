# frozen_string_literal: true

require "test_helper"

class PortfolioPolicyTest < ActiveSupport::TestCase
  def setup
    classroom = create(:classroom)
    @student = User.create!(username: "student", type: "Student", password: "password", classroom: classroom)
    @other_student = User.create!(
      username: "other_student", type: "Student", password: "password",
      classroom: classroom
    )
    @portfolio = Portfolio.create!(user: @student)
    @other_portfolio = Portfolio.create!(user: @other_student)
  end

  test "owner can show their portfolio" do
    assert PortfolioPolicy.new(@student, @portfolio).show?
  end

  test "other users cannot show the portfolio" do
    assert_not PortfolioPolicy.new(@other_student, @portfolio).show?
  end

  test "guest cannot show any portfolio" do
    assert_not PortfolioPolicy.new(nil, @portfolio).show?
  end
end
