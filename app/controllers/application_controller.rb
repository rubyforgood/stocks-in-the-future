# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def after_sign_in_path_for(resource)
    if resource.student?
      user_portfolio_path(resource, resource.portfolio)
    else
      classrooms_path
    end
  end

  def ensure_teacher_or_admin
    return if current_user&.teacher_or_admin?

    flash[:alert] = t("application.access_denied.teacher_or_admin_required")
    redirect_to root_url
  end

  def ensure_admin
    return if current_user&.admin?

    flash[:alert] = t("application.access_denied.admin_required")
    redirect_to root_url
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username type classroom_id])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[username email])
  end

  rescue_from Pundit::NotAuthorizedError do

    if current_user.nil?
      # go to the login page
      redirect_to new_user_session_path, alert: t("devise.failure.unauthenticated")
    elsif current_user.student?
      redirect_to current_user&.portfolio_path, alert: t("application.access_denied.no_access")
    else
      redirect_to root_url, alert: t("application.access_denied.no_access")
    end
  end
end
