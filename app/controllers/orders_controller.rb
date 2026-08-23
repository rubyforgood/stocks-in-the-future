# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :set_order, only: %i[edit update cancel]
  before_action :set_stock, only: %i[new]
  before_action :set_shared_owned, only: %i[new edit]
  before_action :authenticate_user!

  def index
    # A student sees their own orders, but `OrderPolicy::Scope` gives a teacher every order in their
    # classrooms and an admin every order in the system, so this page is unbounded for two of the three
    # roles. 60 orders already measured 8.2 screens.
    @orders = policy_scope(Order)
    sorted = Order.apply_sorting(@orders, params[:sort], params[:direction])
    @orders = sorted.page(params[:page]).per(PER_PAGE)
  end

  def new
    # The user is assigned here as well as in create, because the form shows the
    # trading fee and that depends on whether this user already has a pending
    # order. Without it the form would quote the fee to every student regardless.
    @order = Order.new(action: params[:transaction_type], stock: @stock, user: current_user)
  end

  def edit; end

  def create
    @order = Order.new(order_params.merge(user: current_user))

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

  def set_order
    @order = Order.find(params.expect(:id))
  end

  def set_stock
    @stock = Stock.find(params.expect(:stock_id))
  end

  def set_shared_owned
    @shares_owned = current_user.portfolio&.shares_owned(@stock&.id)
  end

  def setup_error_data
    @stock = @order.stock
    @shares_owned = current_user.portfolio&.shares_owned(@stock&.id)
  end

  # These three read `t(".key")` from private helpers, and Rails resolves a lazy lookup against the current
  # **action** rather than the enclosing method - so all of them land under `orders.cancel.*`, which is where
  # the keys are. `i18n-tasks` infers the scope from the method name instead, so it reports
  # `orders.cancel_order.success` as missing and `orders.cancel.success` as unused. Both are wrong; the
  # lookups were checked at runtime. Do not "fix" either list by moving the keys.
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
