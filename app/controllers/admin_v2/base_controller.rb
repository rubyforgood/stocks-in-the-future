# frozen_string_literal: true

# Base controller for Admin V2 (in-house admin)
# All AdminV2 controllers inherit from this controller.
module AdminV2
  class BaseController < ApplicationController
    layout "admin_v2"

    before_action :authenticate_admin

    private

    def authenticate_admin
      redirect_to root_path, alert: t("application.access_denied.admin_required") unless current_user&.admin?
    end
  end
end
