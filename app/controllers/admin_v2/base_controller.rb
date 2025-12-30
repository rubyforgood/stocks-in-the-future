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

    # Apply sorting to a collection based on params
    # @param collection [ActiveRecord::Relation] The base collection to sort
    # @param default [String] The default column to sort by
    # @return [ActiveRecord::Relation] The sorted collection
    def apply_sorting(collection, default:)
      sort_column = params[:sort].presence || default
      sort_direction = params[:direction] == "desc" ? :desc : :asc
      collection.reorder(sort_column => sort_direction)
    end
  end
end
