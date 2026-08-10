# frozen_string_literal: true

class StocksController < ApplicationController
  before_action :set_stock, only: %i[show]
  before_action :authenticate_user!
  before_action :set_portfolio

  def index
    @stocks = policy_scope(Stock).includes(portfolio_stocks: :portfolio)
    @portfolio = current_user.portfolio if current_user.student?
    load_class_holdings if policy(Stock).show_class_holdings?
  end

  def show
    authorize @stock
  end

  private

  # Who owns each stock, among the people this viewer can see.
  #
  # The scope comes from ClassroomPolicy::Scope - everything for an admin, their own classrooms for a
  # teacher - so the column means one thing and the role decides only the denominator. Two grouped
  # queries, not one per row: asking each stock for its portfolio_stocks is a query per row and still
  # cannot count distinct holders without loading every join row.
  def load_class_holdings
    classroom_ids = policy_scope(Classroom).ids
    @class_classrooms = classroom_ids.size

    # The denominator is students with a portfolio, not students. A student without one cannot hold
    # anything, so counting all of them would understate every row by the size of that gap, and the
    # figure would drift as students are enrolled.
    #
    # Distinct users, not portfolio rows: `portfolios` has no uniqueness constraint on user_id, and
    # `has_one` does not add one - it only decides which row the association returns. A second row for
    # one student would otherwise report "4 students with a portfolio" for three students, which is how
    # this was caught: a factory trait was creating one on top of the one Student#ensure_portfolio makes.
    @class_investors = Portfolio.joins(:user)
      .where(users: { classroom_id: classroom_ids })
      .distinct.count(:user_id)

    # Holders counted the same way, for the same reason: the numerator and the denominator have to be
    # counting the same kind of thing, or "4 of 3" is reachable.
    @class_holdings = PortfolioStock
      .joins(portfolio: :user)
      .where(users: { classroom_id: classroom_ids })
      .group(:stock_id)
      .pluck(Arel.sql("stock_id, COUNT(DISTINCT users.id), SUM(shares)"))
      .to_h { |stock_id, holders, shares| [stock_id, { holders:, shares: }] }
  end

  def set_portfolio
    @portfolio = current_user.portfolio
  end

  def set_stock
    @stock = Stock.find(params.expect(:id))
  end
end
