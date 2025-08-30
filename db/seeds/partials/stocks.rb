# frozen_string_literal: true

Stock::SYMBOLS.each { |ticker_symbol| Stock.find_or_create_by(ticker: ticker_symbol) }

StockPricesUpdateJob.perform_now
