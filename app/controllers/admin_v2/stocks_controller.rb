# frozen_string_literal: true

module AdminV2
  class StocksController < BaseController
    before_action :set_stock, only: %i[show edit update destroy]

    def index
      @stocks = apply_sorting(Stock.all, default: "ticker")

      @breadcrumbs = [
        { label: "Stocks" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Stocks", path: admin_v2_stocks_path },
        { label: @stock.ticker }
      ]
    end

    def new
      @stock = Stock.new

      @breadcrumbs = [
        { label: "Stocks", path: admin_v2_stocks_path },
        { label: "New Stock" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Stocks", path: admin_v2_stocks_path },
        { label: @stock.ticker, path: admin_v2_stock_path(@stock) },
        { label: "Edit" }
      ]
    end

    def create
      @stock = Stock.new(stock_params)

      if @stock.save
        redirect_to admin_v2_stock_path(@stock), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Stocks", path: admin_v2_stocks_path },
          { label: "New Stock" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @stock.update(stock_params)
        redirect_to admin_v2_stock_path(@stock), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Stocks", path: admin_v2_stocks_path },
          { label: @stock.ticker, path: admin_v2_stock_path(@stock) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @stock.destroy
      redirect_to admin_v2_stocks_path, notice: t(".notice")
    rescue ActiveRecord::DeleteRestrictionError => e
      redirect_to admin_v2_stocks_path, alert: "Cannot delete stock: #{e.message}"
    end

    private

    def set_stock
      @stock = Stock.find(params.expect(:id))
    end

    def stock_params
      params.expect(stock: %i[ticker company_name company_website price_cents yesterday_price_cents archived])
    end
  end
end
