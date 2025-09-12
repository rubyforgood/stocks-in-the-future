# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :set_order, only: %i[edit update cancel]
  before_action :set_stock, only: %i[new]
  before_action :set_shared_owned, only: %i[new edit]
  before_action :authenticate_user!

  def index
    @orders = Order.all
  end

  def new
    @order = Order.new(action: params[:transaction_type], stock: @stock, **transaction_fee_params)
  end

  def edit; end

  def create
    @order = Order.new(order_params.merge(user: current_user, **transaction_fee_params))

    respond_to do |format|
      if @order.save
        format.html { redirect_to orders_url, notice: t(".notice") }
        format.turbo_stream { redirect_to orders_url, notice: t(".notice") }
        format.json { render :show, status: :created, location: @order }
      else
        setup_error_data
        format.html { render :new, status: :unprocessable_content }
        format.turbo_stream { render :new, status: :unprocessable_content }
        format.json { render json: @order.errors, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to orders_url, notice: t(".notice") }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @order.errors, status: :unprocessable_content }
      end
    end
  end

  def cancel
    authorize @order

    if @order.pending?
      cancel_order
    else
      invalid_order_response
    end
  end

  private

  # Strong parameters
  def order_params
    params.expect(order: %i[stock_id shares action])
  end

  def transaction_fee_params
    {
      transaction_fee_cents: Order::TRANSACTION_FEE_CENTS
    }
  end

  def set_order
    @order = Order.find(params[:id])
  end

  def set_stock
    @stock = Stock.find(params[:stock_id])
  end

  def set_shared_owned
    @shares_owned = current_user.portfolio&.shares_owned(@stock&.id)
  end

  def setup_error_data
    @stock = @order.stock
    @shares_owned = current_user.portfolio&.shares_owned(@stock&.id)
  end

  def unauthorized_response
    respond_to do |format|
      format.html { redirect_to orders_url, alert: t(".unauthorized") }
      format.json { render json: { error: t(".unauthorized") }, status: :forbidden }
    end
  end

  def cancel_order
    @order.cancel!
    respond_to do |format|
      format.html { redirect_to orders_url, notice: t(".success") }
      format.json { head :no_content }
    end
  end

  def invalid_order_response
    respond_to do |format|
      format.html { redirect_to orders_url, alert: t(".pending_only") }
      format.json { render json: { error: t(".pending_only") }, status: :unprocessable_content }
    end
  end

  def destroy
    @order.destroy!

    respond_to do |format|
      format.html { redirect_to orders_url, notice: t(".notice") }
      format.json { head :no_content }
    end
  end
end
