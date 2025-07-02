# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def after_sign_in_path_for(resource)
    if resource.student?
      portfolio_path(resource.portfolio)
    else
      classrooms_path
    end
  end

  def ensure_teacher_or_admin
    return if current_user&.teacher_or_admin?

    flash[:alert] = t("application.access_denied.teacher_or_admin_required")
    redirect_to root_path
  end

  def ensure_admin
    return if current_user&.admin?

    flash[:alert] = t("application.access_denied.admin_required")
    redirect_to root_path
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[username type classroom_id])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[username email])
  end
end
