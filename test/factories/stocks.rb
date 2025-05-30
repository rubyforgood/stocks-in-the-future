FactoryBot.define do
  factory :stock do
    sequence(:ticker) { |n| "STOCK#{n}" }
    stock_exchange { 'NYSE' }
    company_name { |n| "Sample Company#{n} Inc." }
    company_website { 'https://example.com' }
    description { 'A sample stock for testing' }
    industry { 'Technology' }
    management { 'CEO: John Doe' }
    employees { 1000 }
    competitor_names { |n| "Competitor #{n}, Competitor #{n + 1}" }
    sales_growth { 5.5 }
    industry_avg_sales_growth { 4.2 }
    debt_to_equity { 0.3 }
    industry_avg_debt_to_equity { 0.4 }
    profit_margin { 15.2 }
    industry_avg_profit_margin { 12.8 }
    cash_flow { 1_000_000.00 }
    debt { 500_000.00 }
    price_cents { 12_500 } # $125.00
  end
end
