json.extract! order, :id, :student_id, :stock_id, :shares, :status, :created_at, :updated_at
json.url order_url(order, format: :json)
