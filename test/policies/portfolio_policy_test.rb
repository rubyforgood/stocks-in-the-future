# frozen_string_literal: true

require "test_helper"

class PortfolioPolicyTest < ActiveSupport::TestCase
  def setup
    @classroom = create(:classroom)
    @other_classroom = create(:classroom)

    @student = User.create!(username: "student", type: "Student", password: "password", classroom: @classroom)
    @other_student = User.create!(username: "other_student", type: "Student", password: "password",
                                  classroom: @other_classroom)
    @admin = create(:admin, admin: true)
    @teacher = create(:teacher)

    # Associate teacher with classroom
    @teacher.classrooms << @classroom

    @portfolio = Portfolio.create!(user: @student)
    @other_portfolio = Portfolio.create!(user: @other_student)
  end

  test "owner can show their portfolio" do
    assert PortfolioPolicy.new(@student, @portfolio).show?
  end

  test "other students cannot show the portfolio" do
    assert_not PortfolioPolicy.new(@other_student, @portfolio).show?
  end

  test "guest cannot show any portfolio" do
    assert_not PortfolioPolicy.new(nil, @portfolio).show?
  end

  test "admin can show any portfolio" do
    assert PortfolioPolicy.new(@admin, @portfolio).show?
    assert PortfolioPolicy.new(@admin, @other_portfolio).show?
  end

  test "teacher can show portfolios of students in their classrooms" do
    assert PortfolioPolicy.new(@teacher, @portfolio).show?
  end

  test "teacher cannot show portfolios of students outside their classrooms" do
    assert_not PortfolioPolicy.new(@teacher, @other_portfolio).show?
  end
end
