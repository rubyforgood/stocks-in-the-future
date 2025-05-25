class PortfolioTransaction < ApplicationRecord
  enum :transaction_type, {deposit: 0, withdrawal: 1, credit: 2, debit: 3}
  belongs_to :portfolio
end
