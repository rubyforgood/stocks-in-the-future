# frozen_string_literal: true

require "test_helper"

# Seeds had no test coverage, which is how two bugs survived:
#   - the teacher account could never be created (username missing, save not save!)
#   - re-running seeds duplicated transactions and inflated student balances
class SeedsTest < ActiveSupport::TestCase
  # Same order as db/seeds/development.rb - order matters, models depend on each other.
  PARTIALS = %w[
    years schools school_years grades quarters classrooms users stocks
    portfolio_transactions grade_books_entries orders portfolio_snapshots
  ].freeze

  def run_seeds
    capture_io do
      PARTIALS.each { |partial| load Rails.root.join("db/seeds/partials/#{partial}.rb") }
    end
  end

  test "seeds create all four expected users including the teacher" do
    run_seeds

    %w[teacher@example.com student@example.com admin@example.com mike@example.com].each do |email|
      assert User.exists?(email: email), "expected seeds to create #{email}"
    end
  end

  test "the seeded teacher is valid and can sign in" do
    run_seeds

    teacher = User.find_by(email: "teacher@example.com")
    assert_not_nil teacher, "teacher was not created"
    assert teacher.username.present?, "username is validated for presence, so it must be set"
    assert_equal "Teacher", teacher.type
    assert teacher.valid_password?("password")
  end

  test "seeds are idempotent: running twice does not duplicate records" do
    run_seeds

    before = {
      "User" => User.unscoped.count,
      "PortfolioTransaction" => PortfolioTransaction.count,
      "Order" => Order.count,
      "Portfolio" => Portfolio.count
    }

    run_seeds

    after = {
      "User" => User.unscoped.count,
      "PortfolioTransaction" => PortfolioTransaction.count,
      "Order" => Order.count,
      "Portfolio" => Portfolio.count
    }

    assert_equal before, after, "record counts changed on the second seed run - seeds are not idempotent"
  end

  test "seeds are idempotent: student cash balance does not inflate" do
    run_seeds

    student = User.find_by(email: "student@example.com")
    balance_before = student.portfolio.reload.cash_balance

    run_seeds

    assert_equal balance_before, student.portfolio.reload.cash_balance,
                 "cash balance changed on the second seed run - transactions were duplicated"
  end
end
