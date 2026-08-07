# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      @dashboard = AdminDashboard.new
    end
  end
end
