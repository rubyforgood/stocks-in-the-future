# frozen_string_literal: true

mike = Student.create!(
  username: "mike",
  email: "mike@example.com",
  password: "password",
  password_confirmation: "password",
  admin: false,
  classroom: Classroom.first,
  portfolio_attributes: { current_position: 10_000.0 }
)

portfolio = mike.portfolio
stock = Stock.first

######################################################################
# Create 4 completed orders and transactions for the Student user
######################################################################
pt = PortfolioTransaction.create(
  portfolio: portfolio,
  transaction_type: :deposit,
  amount_cents: 400
)

Order.create!(
  user: mike,
  stock: stock,
  status: :completed,
  portfolio_transaction: pt
)

pt = PortfolioTransaction.create(
  portfolio: portfolio,
  transaction_type: :withdrawal,
  amount_cents: 100
)

Order.create!(
  user: mike,
  stock: stock,
  status: :completed,
  portfolio_transaction: pt
)

pt = PortfolioTransaction.create(
  portfolio: portfolio,
  transaction_type: :credit,
  amount_cents: 1000
)

Order.create!(
  user: mike,
  stock: stock,
  status: :completed,
  portfolio_transaction: pt
)

pt = PortfolioTransaction.create(
  portfolio: portfolio,
  transaction_type: :debit,
  amount_cents: 200
)

Order.create!(
  user: mike,
  stock: stock,
  status: :completed,
  portfolio_transaction: pt
)

Rails.logger.info "Seeded 4 completed orders and transactions for the Student user"
