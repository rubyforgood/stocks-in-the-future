# frozen_string_literal: true

# The figures and the worklist behind the admin dashboard.
#
# The dashboard used to be four cards of links duplicating the sidebar, which is a second
# navigation rather than a dashboard. design.md's dashboard patterns are KPI stat cards plus a
# "needs your attention" worklist, which is also what Stripe, Shopify, Salesforce and Django's
# admin do: figures first, then the things waiting on you.
#
# Queries are counted deliberately. design.md's worklist entry says "no per-row queries", so the
# recent transactions list eager-loads its portfolio and user rather than touching the database
# once per row, and every figure is a single count or sum.
class AdminDashboard
  RECENT_LIMIT = 8

  def students_count
    Student.kept.count
  end

  def classrooms_count
    Classroom.count
  end

  def stocks_count
    Stock.active.count
  end

  # The two figures that are actually work rather than trivia: orders waiting to execute, and
  # grade books entered but not yet paid out.
  def pending_orders_count
    Order.pending.count
  end

  def grade_books_awaiting_payout_count
    GradeBook.where(status: :verified).count
  end

  # Deposits only. Withdrawals and fees are money leaving, so summing every transaction would
  # report a number that means nothing.
  def total_distributed_cents
    PortfolioTransaction.deposits.sum(:amount_cents)
  end

  def recent_transactions
    PortfolioTransaction.includes(portfolio: :user).order(created_at: :desc).limit(RECENT_LIMIT)
  end

  def pending_orders
    Order.pending.includes(:stock, :user).order(created_at: :desc).limit(RECENT_LIMIT)
  end
end
