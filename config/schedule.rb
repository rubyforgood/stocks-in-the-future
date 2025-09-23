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
  # Execute pending stock orders at yesterdays price (internal processing)
  runner "OrderExecutionJob.perform_later"

  # Then update stock prices (external API call)
  runner "StockPricesUpdateJob.perform_later"
end

# Create monthly portfolio snapshots on the last day of every month at 11 PM
# Note: Depends on current stock prices which are updated daily at 6 AM
# Running at month end captures the final portfolio values for that month
every "0 23 L * *" do
  runner "MonthlyPortfolioSnapshotJob.perform_later"
end
