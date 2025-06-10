# frozen_string_literal: true

json.array! @orders, partial: 'orders/order', as: :order
