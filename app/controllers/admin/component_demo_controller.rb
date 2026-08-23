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

      # **A constructed array, not a query.** `Kaminari.paginate_array` gives the component a real
      # paginated collection whatever the database holds, which is what lets the gallery show both states
      # - a live direction and a disabled one - and keeps `component_gallery_test`'s "renders no database
      # records" assertion true.
      sample = Array.new(31) { |i| i + 1 }
      @pagination_first = Kaminari.paginate_array(sample).page(1).per(PER_PAGE)
      @pagination_last = Kaminari.paginate_array(sample).page(2).per(PER_PAGE)

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
