json.extract! stock, :id, :ticker, :stock_exchange, :company_name, :company_website, :created_at, :updated_at
json.url stock_url(stock, format: :json)
