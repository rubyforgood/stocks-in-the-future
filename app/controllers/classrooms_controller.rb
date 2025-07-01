# frozen_string_literal: true

class ClassroomsController < ApplicationController
  before_action :set_classroom, only: %i[show edit update destroy]
  before_action :authenticate_user!
  before_action :ensure_teacher_or_admin, except: %i[index show]

  def index
    @classrooms = current_user.admin? ? Classroom.all : [current_user.classroom].compact
  end

  def show
    @students = @classroom.users.students.includes(:portfolio, :orders)
    @can_manage_students = current_user.teacher_or_admin?
    @classroom_stats = calculate_classroom_stats if @can_manage_students
  end

  def new
    @classroom = Classroom.new
  end

  def edit; end

  def create
    @classroom = Classroom.new(classroom_params.except(:school_name, :year_value))

    school = School.find_or_create_by(name: classroom_params[:school_name])
    year = Year.find_or_create_by(name: classroom_params[:year_value])
    school_year = SchoolYear.find_or_create_by(school: school, year: year)

    @classroom.school_year = school_year

    if @classroom.save
      redirect_to classroom_url(@classroom), notice: t(".notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    school = School.find_or_create_by(name: classroom_params[:school_name])
    year = Year.find_or_create_by(name: classroom_params[:year_value])
    school_year = SchoolYear.find_or_create_by(school: school, year: year)

    @classroom.school_year = school_year

    if @classroom.update(classroom_params.except(:school_name, :year_value))
      redirect_to classroom_url(@classroom), notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
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

  def classroom_params
    params.expect(classroom: %i[name grade school_name year_value])
  end

  def ensure_teacher_or_admin
    redirect_to root_path unless current_user&.teacher_or_admin?
  end

  def calculate_classroom_stats
    return {} unless @classroom

    students = @classroom.users.students
    {
      total_students: students.count,
      active_students: students.joins(:orders).distinct.count,
      total_portfolio_value: students.joins(:portfolio).sum("portfolios.current_position"),
      recent_orders_count: Order.joins(:user).where(users: { classroom: @classroom }).where("orders.created_at > ?",
                                                                                            1.week.ago).count
    }
  end
end
