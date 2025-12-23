# frozen_string_literal: true

module AdminV2
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

      # Demo breadcrumbs
      @breadcrumbs = [
        { label: "Components", path: admin_v2_component_demo_index_path },
        { label: "Demo" }
      ]

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
          label: "User Type",
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
      @user = User.find(params[:id])
      @breadcrumbs = [
        { label: "Components", path: admin_v2_component_demo_index_path },
        { label: "User Details" }
      ]
    end
  end
end
