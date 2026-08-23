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
    # The **ticker**, because that is this page's h1 - `admin/stocks#show` titles with the company name and
    # its trail says that instead. A trail's last item is the page you are on, whichever page that is.
    @breadcrumbs = [{ label: "Trading floor", path: stocks_path }, { label: @stock.ticker }]
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

    # The denominator is **students**, counted the way the roster counts them.
    #
    # It was students *with a portfolio*, which is a distinction the model does not really have -
    # `Student` has `after_create :ensure_portfolio`, so every student gets one - and which forced the
    # description to explain itself with a phrase no teacher uses. Worse, it disagreed with the page a
    # teacher would check it against: `Classroom#students` is scoped `-> { kept }`, so a discarded
    # student is off the roster and their portfolio was still in this count. The roster said 2 and the
    # trading floor said 3.
    students = Student.kept.where(classroom_id: classroom_ids)
    @class_students = students.count

    # Holders filtered the same way, so the numerator is a subset of the denominator - otherwise a
    # discarded student's holding is reachable as "3 of 2". A student without a portfolio simply cannot
    # be a holder, which is the honest reading: they are in the class and do not own it.
    @class_holdings = PortfolioStock
      .joins(portfolio: :user)
      .where(users: { classroom_id: classroom_ids, type: "Student", discarded_at: nil })
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
