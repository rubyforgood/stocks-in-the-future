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
    redirect_to root_path unless current_user&.teacher_or_admin?
  end

  def ensure_admin
    redirect_to root_path unless current_user&.admin?
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :type, :classroom_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :email])
  end
end
