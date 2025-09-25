# frozen_string_literal: true

class ClassroomsController < ApplicationController
  before_action :set_classroom, only: %i[show edit update destroy]
  before_action :authorize_classroom
  before_action :authenticate_user!
  before_action :ensure_teacher_or_admin, except: %i[index show]
  before_action :check_classroom_eligibility, only: :show

  def index
    @classrooms = policy_scope(Classroom).includes(:teachers, students: :portfolio)
  end

  def show
    @students = @classroom.users.students.kept.includes(
      :portfolio,
      :orders,
      portfolio: :portfolio_transactions
    )
    @can_manage_students = current_user.teacher_or_admin?
    @classroom_stats = calculate_classroom_stats if @can_manage_students
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

  def destroy
    @classroom.destroy!

    redirect_to classrooms_url, notice: t(".notice")
  end

  private

  def set_classroom
    @classroom = Classroom.includes(users: :portfolio).find(params[:id].to_i)
  end

  def authorize_classroom
    authorize Classroom
  end

  def classroom_params
    params.expect(classroom: [:name, :grade, :school_id, :year_id, { teacher_ids: [] }])
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
    school_year = SchoolYear.find_or_create_by(school: school, year: year)
    @classroom.school_year = school_year
  end

  def calculate_classroom_stats
    return {} unless @classroom

    students = @classroom.users.students.kept
    {
      total_students: students.count,
      active_students: students.joins(:orders).distinct.count,
      total_portfolio_value: students.joins(:portfolio).sum("portfolios.current_position"),
      recent_orders_count: Order.joins(:user).where(users: { classroom: @classroom }).where("orders.created_at > ?",
                                                                                            1.week.ago).count
    }
  end

  def check_classroom_eligibility
    return if current_user.admin? ||
              (current_user.teacher? &&
                @classroom.teachers.include?(current_user))

    redirect_to root_path, alert: t("application.access_denied.no_access")
  end
end
