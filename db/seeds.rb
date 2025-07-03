# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

year = Year.find_or_create_by(name: "2024")
(2024...2036).each do |i|
  year = Year.find_or_create_by(name: "#{i} - #{i + 1}")
  year.save!
end

school = School.find_or_create_by(name: "Test School")


stocks = [
  { ticker: "AAPL",
    stock_exchange: "NASDAQ",
    company_name: "Apple Inc.",
    company_website: "https://www.apple.com",
    description: "Apple Inc. specializes in the conceptualization, production, and distribution of smartphones, personal computers, tablets, wearable technology. ",
    industry: "Computers/Consumer Electronics",
    management: "Tim Cook (CEO), Kevan Parekh (CFO)",
    employees: 164_000,
    competitor_names: "Samsung, Google, Microsoft, Amazon, Meta",
    sales_growth: 2.02,
    industry_avg_sales_growth: 5.50,
    debt_to_equity: 1.73,
    industry_avg_debt_to_equity: 0.85,
    profit_margin: 23.97,
    industry_avg_profit_margin: 12.50,
    cash_flow: 24_000_000_000.00,
    debt: 95_000_000_000.00,
    price_cents: 19_918
  },
  { ticker: " ",
    stock_exchange: " ",
    company_name: "Coca Cola",
    company_website: " ",
    description: " ",
    industry: " ",
    management: " ",
    employees: 164_000,
  competitor_names: " ",
  sales_growth: 2.02,
  industry_avg_sales_growth: 5.50,
  debt_to_equity: 1.73,
  industry_avg_debt_to_equity: 0.85,
  profit_margin: 23.97,
  industry_avg_profit_margin: 12.50,
  cash_flow: 24_000_000_000.00,
  debt: 95_000_000_000.00,
  price_cents: 19_918
  },
  {
  ticker: " ",
  stock_exchange: " ",
  company_name: "Disney",
  company_website: " ",
  description: " ",
  industry: " ",
  management: " ",
  employees: 164_000,
  competitor_names: " ",
  sales_growth: 2.02,
  industry_avg_sales_growth: 5.50,
  debt_to_equity: 1.73,
  industry_avg_debt_to_equity: 0.85,
  profit_margin: 23.97,
  industry_avg_profit_margin: 12.50,
  cash_flow: 24_000_000_000.00,
  debt: 95_000_000_000.00,
  price_cents: 19_918
  },
  { ticker: " ",
    stock_exchange: " ",
    company_name: "Verizon",
    company_website: " ",
    description: " ",
    industry: " ",
    management: " ",
    employees: 164_000,
    competitor_names: " ",
    sales_growth: 2.02,
    industry_avg_sales_growth: 5.50,
    debt_to_equity: 1.73,
    industry_avg_debt_to_equity: 0.85,
    profit_margin: 23.97,
    industry_avg_profit_margin: 12.50,
    cash_flow: 24_000_000_000.00,
    debt: 95_000_000_000.00,
    price_cents: 19_918
  },
  { ticker: " ",
    stock_exchange: " ",
    company_name: "Southwest",
    company_website: " ",
    description: " ",
    industry: " ",
    management: " ",
    employees: 164_000,
    competitor_names: " ",
    sales_growth: 2.02,
    industry_avg_sales_growth: 5.50,
    debt_to_equity: 1.73,
    industry_avg_debt_to_equity: 0.85,
    profit_margin: 23.97,
    industry_avg_profit_margin: 12.50,
    cash_flow: 24_000_000_000.00,
    debt: 95_000_000_000.00,
    price_cents: 19_918
  },
  { ticker: " ",
    stock_exchange: " ",
    company_name: "Under Armour",
    company_website: " ",
    description: " ",
    industry: " ",
    management: " ",
    employees: 164_000,
    competitor_names: " ",
    sales_growth: 2.02,
    industry_avg_sales_growth: 5.50,
    debt_to_equity: 1.73,
    industry_avg_debt_to_equity: 0.85,
    profit_margin: 23.97,
    industry_avg_profit_margin: 12.50,
    cash_flow: 24_000_000_000.00,
    debt: 95_000_000_000.00,
    price_cents: 19_918
  },
  { ticker: " ",
    stock_exchange: " ",
    company_name: "Gap",
    company_website: " ",
    description: " ",
    industry: " ",
    management: " ",
    employees: 164_000,
    competitor_names: " ",
    sales_growth: 2.02,
    industry_avg_sales_growth: 5.50,
    debt_to_equity: 1.73,
    industry_avg_debt_to_equity: 0.85,
    profit_margin: 23.97,
    industry_avg_profit_margin: 12.50,
    cash_flow: 24_000_000_000.00,
    debt: 95_000_000_000.00,
    price_cents: 19_918
  },
  {
      ticker: " ",
      stock_exchange: " ",
      company_name: "Ford",
      company_website: " ",
      description: " ",
      industry: " ",
      management: " ",
      employees: 164_000,
      competitor_names: " ",
      sales_growth: 2.02,
      industry_avg_sales_growth: 5.50,
      debt_to_equity: 1.73,
      industry_avg_debt_to_equity: 0.85,
      profit_margin: 23.97,
      industry_avg_profit_margin: 12.50,
      cash_flow: 24_000_000_000.00,
      debt: 95_000_000_000.00,
      price_cents: 19_918
  },
  {
      ticker: " ",
      stock_exchange: " ",
      company_name: "Sony",
      company_website: " ",
      description: " ",
      industry: " ",
      management: " ",
      employees: 164_000,
      competitor_names: " ",
      sales_growth: 2.02,
      industry_avg_sales_growth: 5.50,
      debt_to_equity: 1.73,
      industry_avg_debt_to_equity: 0.85,
      profit_margin: 23.97,
      industry_avg_profit_margin: 12.50,
      cash_flow: 24_000_000_000.00,
      debt: 95_000_000_000.00,
      price_cents: 19_918
  },
  {
      ticker: " ",
      stock_exchange: " ",
      company_name: "Sirius XM",
      company_website: " ",
      description: " ",
      industry: " ",
      management: " ",
      employees: 164_000,
      competitor_names: " ",
      sales_growth: 2.02,
      industry_avg_sales_growth: 5.50,
      debt_to_equity: 1.73,
      industry_avg_debt_to_equity: 0.85,
      profit_margin: 23.97,
      industry_avg_profit_margin: 12.50,
      cash_flow: 24_000_000_000.00,
      debt: 95_000_000_000.00,
      price_cents: 19_918
}
]

#finding an existing stock or create using only company_name for now
stocks.each do |stock_data|
  Stock.find_or_create_by(company_name: stock_data[:company_name])
end




school_year_instance = SchoolYear.find_or_create_by!(school: school, year: year)

classroom = Classroom.find_or_create_by(name: "Smith's Sixth Grade", school_year: school_year_instance)

# Clear existing users to ensure idempotency
User.destroy_all

# Create users with usernames and admin flag
Teacher.create!(
  username: "Teacher",
  email: "teacher@example.com",
  password: "password",
  password_confirmation: "password",
  admin: false,
  classroom: classroom
)

Student.create!(
  username: "Student",
  email: "student@example.com",
  password: "password",
  password_confirmation: "password",
  admin: false,
  classroom: classroom,
  portfolio_attributes: { current_position: 10_000.0 }
)

User.create!(
  username: "Admin",
  email: "admin@example.com",
  password: "password",
  password_confirmation: "password",
  admin: true,
  classroom: classroom
)

Rails.logger.info "Seeded 3 users: Teacher, Student, and Admin"
