# frozen_string_literal: true

# Pending buy orders
student = User.find_by(email: "student@example.com")
mike = User.find_by(email: "mike@example.com")

students = [student, mike].compact

if students.any?
  stocks = Stock.limit(5)

  students.each do |student_user|
    if student_user&.portfolio
      portfolio_balance = student_user.portfolio.cash_balance || 0

      if portfolio_balance > 100
        2.times do |i|
          stock = stocks[i]
          if stock
            shares = 1
            cost = stock.price_cents / 100.0

            if cost * shares <= portfolio_balance
              existing_order = Order.find_by(
                user: student_user,
                stock: stock,
                shares: shares,
                status: :pending,
                action: :buy
              )
              
              unless existing_order
                Order.create!(
                  user: student_user,
                  stock: stock,
                  shares: shares,
                  status: :pending,
                  action: :buy
                )
                puts "Created pending buy order: #{student_user.email} - #{shares} shares of #{stock.ticker}"
                Rails.logger.info "Seeded pending buy order for #{student_user.email}: #{shares} shares of #{stock.ticker}"
              else
                puts "Pending buy order already exists: #{student_user.email} - #{shares} shares of #{stock.ticker}"
              end
            end
          end
        end
      end
    end
  end
end

# Pending sell orders
students.each do |student_user|
  if student_user&.portfolio
    existing_portfolio_stock = PortfolioStock.joins(:portfolio)
                                           .where(portfolio: { user: student_user })
                                           .first

    if existing_portfolio_stock && existing_portfolio_stock.shares > 0
      safe_shares = [existing_portfolio_stock.shares.to_i, 1].min
      if safe_shares > 0
        existing_order = Order.find_by(
          user: student_user,
          stock: existing_portfolio_stock.stock,
          shares: safe_shares,
          status: :pending,
          action: :sell
        )
        
        unless existing_order
          Order.create!(
            user: student_user,
            stock: existing_portfolio_stock.stock,
            shares: safe_shares,
            status: :pending,
            action: :sell
          )
          puts "Created pending sell order: #{student_user.email} - #{safe_shares} shares of #{existing_portfolio_stock.stock.ticker}"
          Rails.logger.info "Seeded pending sell order for #{student_user.email}: #{safe_shares} shares of #{existing_portfolio_stock.stock.ticker}"
        else
          puts "Pending sell order already exists: #{student_user.email} - #{safe_shares} shares of #{existing_portfolio_stock.stock.ticker}"
        end
      end
    end
  end
end

# Canceled orders
if students.any?
  stocks = Stock.limit(5)
  
  students.each do |student_user|
    if student_user&.portfolio
      [1, 2].sample.times do |i|
        stock = stocks[i + 2]
        if stock
          shares = [1, 2].sample
          existing_order = Order.find_by(
            user: student_user,
            stock: stock,
            shares: shares,
            status: :canceled,
            action: :sell
          )
          
          unless existing_order
            order = Order.new(
              user: student_user,
              stock: stock,
              shares: shares,
              action: :sell
            )
            order.status = :canceled
            order.save!(validate: false)
            puts "Created canceled order: #{student_user.email} - #{shares} shares of #{stock.ticker}"
            Rails.logger.info "Seeded canceled order for #{student_user.email}: #{shares} shares of #{stock.ticker}"
          else
            puts "Canceled order already exists: #{student_user.email} - #{shares} shares of #{stock.ticker}"
          end
        end
      end
    end
  end
else
  puts "No student users found. Skipping orders seeding."
  Rails.logger.warn "No student users found. Skipping orders seeding."
end
