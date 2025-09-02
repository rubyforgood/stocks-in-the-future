# frozen_string_literal: true

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
