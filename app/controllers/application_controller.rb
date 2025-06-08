class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def after_sign_in_path_for(resource)
    case resource.type
    when 'Student'
      portfolio_path(resource.portfolio)
    when 'Teacher', 'Admin'
      classrooms_path
    else
      root_path
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
