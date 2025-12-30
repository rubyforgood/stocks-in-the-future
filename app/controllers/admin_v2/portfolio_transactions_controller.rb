# frozen_string_literal: true

module AdminV2
  class PortfolioTransactionsController < BaseController
    before_action :set_portfolio_transaction, only: %i[show edit update destroy]

    def show
      authorize @portfolio_transaction

      @breadcrumbs = [
        { label: "Portfolio Transaction ##{@portfolio_transaction.id}" }
      ]
    end

    def new
      @portfolio_transaction = PortfolioTransaction.new
      authorize @portfolio_transaction

      @breadcrumbs = [
        { label: "Portfolio Transactions", path: "#" },
        { label: "New" }
      ]
    end

    def edit
      authorize @portfolio_transaction

      @breadcrumbs = [
        { label: "Portfolio Transaction ##{@portfolio_transaction.id}",
          path: admin_v2_portfolio_transaction_path(@portfolio_transaction) },
        { label: "Edit" }
      ]
    end

    def create
      @portfolio_transaction = PortfolioTransaction.new(portfolio_transaction_params)
      authorize @portfolio_transaction

      if @portfolio_transaction.save
        redirect_to admin_v2_portfolio_transaction_path(@portfolio_transaction),
                    notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Portfolio Transactions", path: "#" },
          { label: "New" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      authorize @portfolio_transaction

      if @portfolio_transaction.update(portfolio_transaction_params)
        redirect_to admin_v2_portfolio_transaction_path(@portfolio_transaction),
                    notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Portfolio Transaction ##{@portfolio_transaction.id}",
            path: admin_v2_portfolio_transaction_path(@portfolio_transaction) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @portfolio_transaction
      @portfolio_transaction.destroy

      redirect_to admin_v2_root_path, notice: t(".notice")
    end

    private

    def set_portfolio_transaction
      @portfolio_transaction = PortfolioTransaction.find(params.expect(:id))
    end

    def portfolio_transaction_params
      params.expect(portfolio_transaction: %i[portfolio_id transaction_type reason description amount_cents])
    end
  end
end
