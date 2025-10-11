# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_stocks

  protected

  def ensure_teacher_or_admin
    authorize :application, :teacher_or_admin_required?
  end

  def ensure_admin
    authorize :application, :admin_required?
  end

  private

  def set_stocks
    @stocks = policy_scope(Stock).includes(portfolio_stocks: :portfolio)
  end

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
