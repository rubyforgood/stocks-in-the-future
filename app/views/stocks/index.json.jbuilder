# frozen_string_literal: true

json.array! @stocks, partial: 'stocks/stock', as: :stock
