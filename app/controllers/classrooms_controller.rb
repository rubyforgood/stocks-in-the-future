# frozen_string_literal: true

class ClassroomsController < ApplicationController
  before_action :set_classroom, only: %i[show edit update toggle_trading]
  before_action :authorize_classroom, except: %i[edit update toggle_trading]
  before_action :authorize_classroom_instance, only: %i[edit update toggle_trading]
  before_action :authenticate_user!
  before_action :ensure_teacher_or_admin, except: %i[index show]
  before_action :check_classroom_eligibility, only: :show

  def index
    @classrooms = policy_scope(Classroom).includes(:teachers, students: :portfolio)
    @classrooms = Classroom.apply_sorting(@classrooms, params[:sort], params[:direction])
  end

  def show
    facade = ClassroomFacade.new(@classroom)
    @students = facade.students
    @can_manage_students = current_user.teacher_or_admin?
    @classroom_stats = facade.stats if @can_manage_students
  end

  def new
    @classroom = Classroom.new
    dropdown_data
  end

  def edit
    dropdown_data
  end

  def create
    @classroom = Classroom.new(classroom_params.except(:school_id, :year_id))
    assign_school_year_to_classroom

    if @classroom.save
      redirect_to classroom_url(@classroom), notice: t(".notice")
    else
      dropdown_data
      render :new, status: :unprocessable_content
    end
  end

  def update
    assign_school_year_to_classroom

    if @classroom.update(classroom_params.except(:school_id, :year_id))
      redirect_to classroom_url(@classroom), notice: t(".notice")
    else
      dropdown_data
      render :edit, status: :unprocessable_content
    end
  end

  def toggle_trading
    if @classroom.update(trading_enabled: !@classroom.trading_enabled)
      notice_key = @classroom.trading_enabled? ? :enabled : :disabled
      redirect_to classroom_url(@classroom), notice: t(".#{notice_key}")
    else
      redirect_to classroom_url(@classroom), alert: t(".alert")
    end
  end

  private

  def set_classroom
    @classroom = Classroom.includes(users: :portfolio).find(params.expect(:id).to_i)
  end

  def authorize_classroom
    authorize Classroom
  end

  def authorize_classroom_instance
    authorize @classroom
  end

  # The permitted list comes from the policy, not from here, because it differs by role: an admin may
  # move a classroom between school years and change who teaches it, a teacher may not. Keeping it in
  # ClassroomPolicy puts "may they?" and "what of it?" in one file - a teacher's crafted request
  # carrying school_id or teacher_ids is dropped here rather than relying on the form not to show them.
  #
  # Pundit's `permitted_attributes` does the permitting itself - it returns filtered params, not the
  # list - so this replaces the whole `params.expect(...)` rather than being handed to it. Passing its
  # return value into `expect` raises ParameterMissing and every update 400s.
  #
  # Classroom.new for create: only an admin can reach it, and permitted_attributes needs a record to be
  # asked about even though this policy's answer depends on the user alone.
  def classroom_params
    permitted_attributes(@classroom || Classroom.new)
  end

  def dropdown_data
    @schools = School.order(:name)
    @years = Year.order(:name)
    @teachers = Teacher.all.sort_by(&:display_name)
  end

  def assign_school_year_to_classroom
    return unless classroom_params[:school_id].present? && classroom_params[:year_id].present?

    school = School.find(classroom_params[:school_id])
    year = Year.find(classroom_params[:year_id])
    school_year = SchoolYear.find_or_create_by!(school: school, year: year)
    @classroom.school_year = school_year
  end

  def check_classroom_eligibility
    # Redirect if classroom is archived and user is not an admin
    if @classroom.archived? && !current_user.admin?
      redirect_to root_path, alert: t("classrooms.archived.alert")
      return
    end

    return if current_user.admin? ||
              (current_user.teacher? &&
                @classroom.teachers.include?(current_user))

    redirect_to root_path, alert: t("application.access_denied.no_access")
  end
end
