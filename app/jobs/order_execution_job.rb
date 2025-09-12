# frozen_string_literal: true

class OrderExecutionJob < ApplicationJob
  queue_as :default

  def perform
    pending_orders = Order.pending

    pending_orders.each do |pending_order|
      ExecuteOrder.execute(pending_order)
    end
  end
end
