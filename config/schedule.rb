# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Learn more: http://github.com/javan/whenever

# Set the environment path to ensure proper Rails loading
env :PATH, ENV.fetch("PATH", nil)

# Run stock-related jobs at 1:00 AM Eastern Time every day
every 1.day, at: "6:00 am" do
  # Update stock prices first (external API call)
  runner "StockPricesUpdateJob.perform_later"

  # Then execute pending stock orders (internal processing)
  runner "OrderExecutionJob.perform_later"
end
