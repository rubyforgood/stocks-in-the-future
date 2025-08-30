# frozen_string_literal: true

mike = User.find_by(email: "mike@example.com")

if mike
  portfolio = Portfolio.find_or_create_by(user: mike)
  stock = Stock.first

  ######################################################################
  # Create 4 completed orders and transactions for the Student user
  ######################################################################
  pt = PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 400_000
  )

  Order.create!(
    user: mike,
    stock: stock,
    shares: 2,
    status: :completed,
    portfolio_transaction: pt,
    action: :buy
  )

  pt = PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :withdrawal,
    amount_cents: 100
  )

  Order.create!(
    user: mike,
    stock: stock,
    shares: 3,
    status: :completed,
    portfolio_transaction: pt,
    action: :buy
  )

  pt = PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :credit,
    amount_cents: 1000
  )

  Order.create!(
    user: mike,
    stock: stock,
    shares: 4,
    status: :completed,
    portfolio_transaction: pt,
    action: :buy
  )

  pt = PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :debit,
    amount_cents: 200
  )

  Order.create!(
    user: mike,
    stock: stock,
    shares: 1,
    status: :completed,
    portfolio_transaction: pt,
    action: :buy
  )

  puts "Seeded 4 completed orders and transactions for the Student user 'Mike'"
  Rails.logger.info "Seeded 4 completed orders and transactions for the Student user 'Mike"
else
  puts "Student user 'Mike' not found. Skipping portfolio transactions seeding."
  Rails.logger.warn "Student user 'Mike' not found. Skipping portfolio transactions seeding."
end
