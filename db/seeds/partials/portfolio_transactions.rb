# frozen_string_literal: true

# Create transactions for Student user
student = User.find_by(email: "student@example.com")

if student
  portfolio = Portfolio.find_or_create_by(user: student)

  # Initial deposit to give student starting balance
  PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 10_000_00
  )

  # Add earnings transactions with reasons for testing
  PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 500_00,
    reason: :attendance_earnings
  )

  PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 500_00,
    reason: :reading_earnings
  )

  PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 100_00,
    reason: :math_earnings
  )

  PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 50_00,
    reason: :awards
  )

  PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 25_00,
    reason: :transaction_fees
  )

  puts "Seeded portfolio transactions for Student user"
  Rails.logger.info "Seeded portfolio transactions for Student user"
else
  puts "Student user not found. Skipping Student portfolio transactions seeding."
  Rails.logger.warn "Student user not found. Skipping Student portfolio transactions seeding."
end

# Create transactions for Mike user
mike = User.find_by(email: "mike@example.com")

if mike
  portfolio = Portfolio.find_or_create_by(user: mike)

  pt = PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 15_000_00
  )

  stocks = Stock.limit(3)
  shares = 2

  stocks.each do |stock|
    next unless stock.price_cents
    total_price_cents = (stock.price_cents * shares)

    order = Order.create!(
      user: mike,
      stock: stock,
      shares: shares,
      status: :pending,
      portfolio_transaction: pt,
      action: :buy
    )
    ExecuteOrder.execute(order)
  end

  shares = 1

  stocks.each do |stock|
    next unless stock.price_cents
    total_price_cents = (stock.price_cents * shares)

    order = Order.create!(
      user: mike,
      stock: stock,
      shares: shares,
      status: :pending,
      portfolio_transaction: pt,
      action: :sell
    )
    ExecuteOrder.execute(order)
  end

  pt = PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :withdrawal,
    amount_cents: 100_00
  )

  pt = PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 10_000_00
  )

  existing_stock_ids = Order.where(user: mike, action: :buy).pluck(:stock_id).uniq
  stocks = Stock.where.not(id: existing_stock_ids).limit(1)

  stocks.each do |stock|
    next unless stock.price_cents
    shares = 1
    total_price_cents = (stock.price_cents * shares)

    order = Order.create!(
      user: mike,
      stock: stock,
      shares: shares,
      status: :pending,
      portfolio_transaction: pt,
      action: :buy
    )
    ExecuteOrder.execute(order)
  end

  puts "Seeded three completed orders and transactions for the Student user 'Mike'"
  Rails.logger.info "Seeded three completed orders and transactions for the Student user 'Mike"
else
  puts "Student user 'Mike' not found. Skipping portfolio transactions seeding."
  Rails.logger.warn "Student user 'Mike' not found. Skipping portfolio transactions seeding."
end
