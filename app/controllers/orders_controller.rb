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
    @order = Order.new(action: params[:transaction_type], stock: @stock)
  end

  def edit; end

  def create
    @order = Order.new(order_params.merge(user: current_user))

    respond_to do |format|
      if @order.save
        format.html { redirect_to orders_url, notice: t(".notice") }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new, status: :unprocessable_content }
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
end

def destroy
  @order.destroy!

  respond_to do |format|
    format.html { redirect_to orders_url, notice: t(".notice") }
    format.json { head :no_content }
  end
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

def order_params
  params.expect(order: %i[stock_id shares action])
end
