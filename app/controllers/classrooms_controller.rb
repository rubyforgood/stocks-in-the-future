class ClassroomsController < ApplicationController
  before_action :set_classroom, only: %i[show edit update destroy]
  before_action :authenticate_user!

  def index
    @classrooms = Classroom.all
  end

  def show
  end

  def new
    @classroom = Classroom.new
  end

  def edit
  end

  def create
    @classroom = Classroom.new(classroom_params)

    if @classroom.save
      redirect_to classroom_url(@classroom), notice: t(".notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @classroom.update(classroom_params)
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
    @classroom = Classroom.find(params[:id])
  end

  def classroom_params
    params.require(:classroom).permit(:name, :year_id, :school_id, :grade)
  end
end
