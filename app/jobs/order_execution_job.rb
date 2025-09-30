# frozen_string_literal: true

class OrderExecutionJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform
    Rails.logger.info "Starting order execution job at #{Time.current}"

    pending_orders = Order.pending
    Rails.logger.info "Found #{pending_orders.count} pending orders to execute"

    if pending_orders.empty?
      Rails.logger.info "No pending orders to execute"
    else
      pending_orders.each do |pending_order|
        ExecuteOrder.execute(pending_order)
      end
      TransactionFeeProcessor.execute(pending_orders)
      Rails.logger.info "Successfully executed #{pending_orders.count} orders"
    end

    # Chain to StockPricesUpdateJob after successful order execution to avoid conflicts
    Rails.logger.info "Scheduling stock prices update job"
    StockPricesUpdateJob.perform_later

    Rails.logger.info "Order execution job completed successfully"
  rescue StandardError => e
    Rails.logger.error "Order execution job failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
