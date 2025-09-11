# frozen_string_literal: true

alphabetic_seed_stocks = [
  # Existing stocks
  { ticker: "F",     stock_exchange: "NYSE",   company_name: "Ford Motor Company",         company_website: "https://www.ford.com",         description: "Ford Motor Company designs, manufactures, markets, and services a full line of Ford trucks, utility vehicles, and cars worldwide.",         industry: "Automobiles",         management: "Jim Farley (CEO), John Lawler (CFO)",         employees: 190_000,         competitor_names: "General Motors, Tesla, Toyota, Stellantis",         sales_growth: 11.8,         industry_avg_sales_growth: 6.4,         debt_to_equity: 1.85,         industry_avg_debt_to_equity: 0.95,         profit_margin: 3.7,         industry_avg_profit_margin: 7.2,         cash_flow: 11_500_000_000.00,         debt: 96_000_000_000.00,         price_cents: 1_177 },
  { ticker: "KO",    stock_exchange: "NYSE",   company_name: "The Coca-Cola Company",       company_website: "https://www.coca-colacompany.com", description: "The Coca-Cola Company manufactures, retails, and markets nonalcoholic beverage concentrates and syrups worldwide.", industry: "Beverages", management: "James Quincey (CEO), John Murphy (CFO)", employees: 86_200, competitor_names: "PepsiCo, Dr Pepper Snapple Group, Monster Beverage", sales_growth: 11.2, industry_avg_sales_growth: 5.50, debt_to_equity: 1.65, industry_avg_debt_to_equity: 0.85, profit_margin: 25.4, industry_avg_profit_margin: 12.50, cash_flow: 10_800_000_000.00, debt: 37_000_000_000.00, price_cents: 6_899 },
  { ticker: "SONY",  stock_exchange: "NYSE",   company_name: "Sony Group Corporation",      company_website: "https://www.sony.com",  description: "Sony Group Corporation operates as a technology and media company that develops, produces, manufactures, and sells various products worldwide.", industry: "Consumer Electronics", management: "Kenichiro Yoshida (CEO), Hiroki Totoki (CFO)", employees: 108_900, competitor_names: "Samsung, Apple, Nintendo, Microsoft", sales_growth: 4.8, industry_avg_sales_growth: 6.2, debt_to_equity: 0.35, industry_avg_debt_to_equity: 0.45, profit_margin: 13.2, industry_avg_profit_margin: 8.9, cash_flow: 8_500_000_000.00, debt: 15_200_000_000.00, price_cents: 2_752 },
  { ticker: "VZ",    stock_exchange: "NYSE",   company_name: "Verizon Communications Inc.", company_website: "https://www.verizon.com",  description: "Verizon Communications Inc., through its subsidiaries, offers communications, technology, information, and entertainment products and services to consumers, businesses, and governmental entities worldwide.", industry: "Telecommunications Services", management: "Hans Vestberg (CEO), Matt Ellis (CFO)", employees: 117_100, competitor_names: "AT&T, T-Mobile, Comcast, Charter Communications", sales_growth: 2.1, industry_avg_sales_growth: 3.8, debt_to_equity: 1.8, industry_avg_debt_to_equity: 1.5, profit_margin: 17.2, industry_avg_profit_margin: 12.4, cash_flow: 23_700_000_000.00, debt: 176_200_000_000.00, price_cents: 4_423 },

  # Newly added stocks (as per issue #493)
  { ticker: "NKE",  company_name: "Nike, Inc." },
  { ticker: "CCL",  company_name: "Carnival Corporation & plc" },
  { ticker: "KHC",  company_name: "The Kraft Heinz Company" },
  { ticker: "MAT",  company_name: "Mattel, Inc." },
  { ticker: "BAC",  company_name: "Bank of America Corporation" },
  { ticker: "IBIT", company_name: "iShares Bitcoin ETF" }
]

alphabetic_seed_stocks.each do |stock_data|
  stock = Stock.find_or_create_by(ticker: stock_data[:ticker])
  stock.update!(stock_data)
end
