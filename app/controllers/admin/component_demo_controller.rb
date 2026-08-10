# frozen_string_literal: true

module Admin
  class ComponentDemoController < BaseController
    # rubocop:disable Metrics/MethodLength
    def index
      # Demo data for table component - apply sorting before limit
      @users = User.all

      # Apply sorting if params present
      if params[:sort].present?
        direction = params[:direction] == "desc" ? :desc : :asc
        @users = @users.order(params[:sort] => direction)
      end

      @users = @users.limit(10)

      # Demo data for show component
      @sample_user = User.first || User.new(
        email: "demo@example.com",
        name: "Demo User",
        admin: true,
        created_at: Time.current
      )

      # The trail read "Components / Demo" on the page that *is* the component index, which also made the
      # document title "Demo | Admin | ...", since the layout derives the title from the last crumb.
      @breadcrumbs = [{ label: "Component demo" }]

      # Demo table columns
      @columns = [
        { attribute: :id, label: "ID", sortable: true },
        { attribute: :email, label: "Email", sortable: true },
        { attribute: :name, label: "Name", sortable: true },
        { attribute: :admin, label: "Admin", sortable: true },
        { attribute: :created_at, label: "Created", sortable: true }
      ]

      # Demo filters
      @filters = [
        {
          name: :type,
          label: "User type",
          options: [["All", ""], ["Admin", "admin"], ["Teacher", "teacher"], ["Student", "student"]]
        },
        {
          name: :status,
          label: "Status",
          options: [["All", ""], ["Active", "active"], ["Inactive", "inactive"]]
        }
      ]
    end
    # rubocop:enable Metrics/MethodLength

    # Preview: what the trading floor could show a teacher.
    #
    # The live page gives a teacher two columns - the buy list with the buying removed - because
    # StockPolicy#show_holdings? requires a student with a persisted portfolio. This renders the three
    # candidate additions against real records so the numbers are real ones.
    def trading_floor_columns
      @stocks = Stock.active.order(:ticker)

      # The aggregate that does not exist anywhere in the app today: holdings grouped by stock, scoped
      # to the classrooms the viewer can see. One query, no N+1 - the alternative, asking each stock for
      # its portfolio_stocks, is 10 queries and cannot count distinct holders without loading them all.
      @classroom_ids = Classroom.pluck(:id)
      @holdings = PortfolioStock
        .joins(portfolio: :user)
        .where(users: { classroom_id: @classroom_ids })
        .group(:stock_id)
        .pluck(Arel.sql("stock_id, COUNT(DISTINCT portfolio_id), SUM(shares)"))
        .to_h { |stock_id, holders, shares| [stock_id, { holders:, shares: }] }

      # The denominator. A count of students is the wrong one: a student with no portfolio cannot hold
      # anything, so "3 of 40" would understate every row by the size of the gap.
      @investors = Portfolio.joins(:user).where(users: { classroom_id: @classroom_ids }).count

      @breadcrumbs = [
        { label: "Component demo", path: admin_component_demo_index_path },
        { label: "Trading floor columns" }
      ]
    end

    def show
      @user = User.find(params.expect(:id))
      @breadcrumbs = [
        { label: "Component demo", path: admin_component_demo_index_path },
        { label: "User details" }
      ]
    end

    def form
      @user = User.first || User.new(email: "", name: "", admin: false)

      # Add validation errors for demo purposes if requested
      if params[:show_errors] == "true"
        @user.errors.add(:email, "can't be blank")
        @user.errors.add(:name, "is too short (minimum is 3 characters)")
      end

      @breadcrumbs = [
        { label: "Component demo", path: admin_component_demo_index_path },
        { label: "Form builder demo" }
      ]
    end
  end
end
