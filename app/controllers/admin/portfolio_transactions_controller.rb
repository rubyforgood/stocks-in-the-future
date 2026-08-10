# frozen_string_literal: true

module Admin
  # **No per-record `authorize` here, and that is the answer to the six TODOs this used to carry.**
  #
  # Authorization in this namespace is `Admin::BaseController#authenticate_admin`, which redirects anyone
  # who is not an admin before an action runs. Every one of the ten admin controllers relies on it; the
  # single `authorize` elsewhere in `admin/` is `classrooms#toggle_archive`, and that one is meaningful
  # because `ClassroomPolicy` exists and teachers reach classroom actions on the app side too.
  #
  # Adding calls here would need a `PortfolioTransactionPolicy` whose every method returned `user.admin?`
  # - a policy that restates the before_action, for one controller out of ten, implying the other nine
  # were missing something they are not. Six commented-out `authorize` lines said the opposite for as long
  # as they sat there.
  #
  # What makes the guarantee real is a test rather than a call: `admin_access_test` walks every admin
  # route and asserts a teacher, a student and a signed-out visitor are all turned away. A `before_action`
  # in a superclass is only as good as the proof that nothing bypasses it.
  class PortfolioTransactionsController < BaseController
    before_action :set_portfolio_transaction, only: %i[show edit update destroy]

    def index
      @portfolio_transactions = apply_sorting(
        PortfolioTransaction.includes(portfolio: :user),
        default: "created_at"
      )
      @breadcrumbs = [{ label: "Portfolio transactions" }]
    end

    def show
      @breadcrumbs = [
        { label: "Portfolio transaction ##{@portfolio_transaction.id}" }
      ]
    end

    def new
      @portfolio_transaction = PortfolioTransaction.new

      @breadcrumbs = [
        { label: "Portfolio transactions", path: admin_portfolio_transactions_path },
        { label: "New" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Portfolio transaction ##{@portfolio_transaction.id}",
          path: admin_portfolio_transaction_path(@portfolio_transaction) },
        { label: "Edit" }
      ]
    end

    def create
      @portfolio_transaction = PortfolioTransaction.new(portfolio_transaction_params)

      if @portfolio_transaction.save
        redirect_to admin_portfolio_transaction_path(@portfolio_transaction),
                    notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Portfolio transactions", path: admin_portfolio_transactions_path },
          { label: "New" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @portfolio_transaction.update(portfolio_transaction_params)
        redirect_to admin_portfolio_transaction_path(@portfolio_transaction),
                    notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Portfolio transaction ##{@portfolio_transaction.id}",
            path: admin_portfolio_transaction_path(@portfolio_transaction) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @portfolio_transaction.destroy

      redirect_to admin_root_path, notice: t(".notice")
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
