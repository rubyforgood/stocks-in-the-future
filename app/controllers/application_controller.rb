# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Rows per page, for every paginated index on both halves.
  #
  # 25 is Stripe's figure and Kaminari's default; Shopify uses 50, GitHub 30, Administrate 20. The measured
  # argument for the low end is the Chromebook this app is used on: at 1366x768 the viewport is 625px and
  # an admin transactions row is ~48px, so 25 rows is about two screens of scroll. Unpaginated, 300 rows
  # measured 15,534px - **24.9 screens** - and 58,190px at 375px, where the rows stack.
  PER_PAGE = 25

  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def ensure_teacher_or_admin
    authorize :application, :teacher_or_admin_required?
  end

  def ensure_admin
    authorize :application, :admin_required?
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
