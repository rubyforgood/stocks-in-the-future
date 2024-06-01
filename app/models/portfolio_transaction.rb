class PortfolioTransaction < ApplicationRecord
  enum transaction_type: {deposit: 0, withdrawal: 1, credit: 2, debit: 3}
  belongs_to :portfolio

  # Retrieve transactions occuring in a certain date range
  def transactions_by_date_range(start_date:, end_date:)
    # Logic to format and return this info
  end
end
