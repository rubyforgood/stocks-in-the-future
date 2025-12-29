# frozen_string_literal: true

module AdminV2
  class PortfolioStocksController < BaseController
    before_action :set_portfolio_stock, only: %i[show edit update destroy]

    def index
      @portfolio_stocks = apply_sorting(PortfolioStock.includes(:portfolio, :stock), default: "created_at")

      @breadcrumbs = [
        { label: "Portfolio Stocks" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Portfolio Stocks", path: admin_v2_portfolio_stocks_path },
        { label: "Portfolio Stock ##{@portfolio_stock.id}" }
      ]
    end

    def new
      @portfolio_stock = PortfolioStock.new
      @breadcrumbs = [
        { label: "Portfolio Stocks", path: admin_v2_portfolio_stocks_path },
        { label: "New Portfolio Stock" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Portfolio Stocks", path: admin_v2_portfolio_stocks_path },
        { label: "Portfolio Stock ##{@portfolio_stock.id}", path: admin_v2_portfolio_stock_path(@portfolio_stock) },
        { label: "Edit" }
      ]
    end

    def create
      @portfolio_stock = PortfolioStock.new(portfolio_stock_params)

      if @portfolio_stock.save
        redirect_to admin_v2_portfolio_stock_path(@portfolio_stock), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Portfolio Stocks", path: admin_v2_portfolio_stocks_path },
          { label: "New Portfolio Stock" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @portfolio_stock.update(portfolio_stock_params)
        redirect_to admin_v2_portfolio_stock_path(@portfolio_stock), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Portfolio Stocks", path: admin_v2_portfolio_stocks_path },
          { label: "Portfolio Stock ##{@portfolio_stock.id}", path: admin_v2_portfolio_stock_path(@portfolio_stock) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @portfolio_stock.destroy
      redirect_to admin_v2_portfolio_stocks_path, notice: t(".notice")
    end

    private

    def set_portfolio_stock
      @portfolio_stock = PortfolioStock.find(params[:id])
    end

    def portfolio_stock_params
      params.expect(portfolio_stock: %i[portfolio_id stock_id purchase_price shares])
    end
  end
end
