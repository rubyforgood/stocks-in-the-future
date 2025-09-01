# frozen_string_literal: true

mike = User.find_by(email: "mike@example.com")

if mike
  portfolio = Portfolio.find_or_create_by(user: mike)

  ######################################################################################
  # Seed Mike's portfolio with initial deposit, purchases, sells, and cash transactions
  ######################################################################################

  # Deposit $15,000.00 into the portfolio as initial cash
  pt = PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 15_000_00 # $15,000.00
  )

  # Purchase 2 shares each of the first 3 stocks
  stocks = Stock.limit(3)
  shares = 2

  stocks.each do |stock|
    total_price_cents = (stock.price_cents * shares)

    order = Order.create!(
      user: mike,
      stock: stock,
      shares: shares,
      status: :pending,
      portfolio_transaction: pt,
      action: :buy
    )
    PurchaseStock.execute(order)
  end

  # Sell 1 share each of those 3 stocks
  shares = 1

  stocks.each do |stock|
    total_price_cents = (stock.price_cents * shares)

    order = Order.create!(
      user: mike,
      stock: stock,
      shares: shares,
      status: :pending,
      portfolio_transaction: pt,
      action: :sell
    )
    PurchaseStock.execute(order)
  end

  # Withdraw $100.00 from the portfolio
  pt = PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :withdrawal,
    amount_cents: 100_00
  )

  # Deposit $10000.00 into the portfolio
  pt = PortfolioTransaction.create(
    portfolio: portfolio,
    transaction_type: :deposit,
    amount_cents: 10_000_00
  )

  # Buy 1 share of a new stock not already owned by Mike
  existing_stock_ids = Order.where(user: mike, action: :buy).pluck(:stock_id).uniq
  stocks = Stock.where.not(id: existing_stock_ids).limit(1)

  stocks.each do |stock|
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
    PurchaseStock.execute(order)
  end

  puts "Seeded three completed orders and transactions for the Student user 'Mike'"
  Rails.logger.info "Seeded three completed orders and transactions for the Student user 'Mike"
else
  puts "Student user 'Mike' not found. Skipping portfolio transactions seeding."
  Rails.logger.warn "Student user 'Mike' not found. Skipping portfolio transactions seeding."
end
