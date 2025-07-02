# frozen_string_literal: true

class PortfolioTransaction < ApplicationRecord
  # deposit/witdrawal is for cash transactions ie grades and attendance
  # credit/debit is for stock transactions ie buy/sell stocks
  enum :transaction_type, { deposit: 0, withdrawal: 1, credit: 2, debit: 3 }
  belongs_to :portfolio
end
