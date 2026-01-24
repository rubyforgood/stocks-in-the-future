# frozen_string_literal: true

class OrderExecutionJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform
    Rails.logger.info "[RECURRING JOB] OrderExecutionJob starting at #{Time.current} (#{Time.zone})"
    Rails.logger.info "[RECURRING JOB] Current environment: #{Rails.env}"

    pending_orders = Order.pending
    log_pending_orders_count(pending_orders)

    process_pending_orders(pending_orders) unless pending_orders.empty?
    schedule_stock_prices_update

    Rails.logger.info "Order execution job completed successfully"
  rescue StandardError => e
    log_execution_error(e)
    raise # Re-raise to trigger retry mechanism
  end

  private

  def log_pending_orders_count(pending_orders)
    Rails.logger.info "Found #{pending_orders.count} pending orders to execute"
  end

  def process_pending_orders(pending_orders)
    execute_orders(pending_orders)
    process_transaction_fees(pending_orders)
    log_successful_execution(pending_orders)
  end

  def execute_orders(pending_orders)
    pending_orders.each do |pending_order|
      ExecuteOrder.execute(pending_order)
    end
  end

  def process_transaction_fees(pending_orders)
    TransactionFeeProcessor.execute(pending_orders)
  end

  def log_successful_execution(pending_orders)
    Rails.logger.info "Successfully executed #{pending_orders.count} orders"
  end

  # TODO: Remove this from OrderExecutionJob. StockPricesUpdateJob should be
  # its own independent recurring job, not coupled to order execution.
  def schedule_stock_prices_update
    Rails.logger.info "Scheduling stock prices update job"
    StockPricesUpdateJob.perform_later
  end

  def log_execution_error(error)
    Rails.logger.error "Order execution job failed: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
  end
end
