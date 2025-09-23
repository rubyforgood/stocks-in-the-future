# frozen_string_literal: true
require "test_helper"

class PortfolioPolicyTest < ActiveSupport::TestCase
  def setup
    @student = User.create!(username: "student", type: "Student", password: "password")
    @other_student = User.create!(username: "other_student", type: "Student", password: "password")
    @portfolio = Portfolio.create!(user: @student)
    @other_portfolio = Portfolio.create!(user: @other_student)
  end

  test "owner can show their portfolio" do
    assert PortfolioPolicy.new(@student, @portfolio).show?
  end

  test "other users cannot show the portfolio" do
    refute PortfolioPolicy.new(@other_student, @portfolio).show?
  end

  test "guest cannot show any portfolio" do
    refute PortfolioPolicy.new(nil, @portfolio).show?
  end
end
