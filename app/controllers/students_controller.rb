# frozen_string_literal: true

class StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_teacher_or_admin
  before_action :set_classroom
  before_action :set_student, except: %i[new create]

  def show; end

  def new
    @student = Student.new(classroom: @classroom)
  end

  def edit; end

  def create
    @student = Student.new(student_params)
    @student.classroom = @classroom
    @student.password = generate_memorable_password

    if @student.save
      redirect_to classroom_path(@classroom),
                  notice: t(".notice", username: @student.username, password: @student.password)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @student.update(student_params)
      redirect_to classroom_path(@classroom), notice: t(".notice")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    username = @student.username
    @student.destroy
    redirect_to classroom_path(@classroom), notice: t(".notice", username: username)
  end

  def reset_password
    new_password = generate_memorable_password
    @student.update!(password: new_password)
    redirect_to classroom_path(@classroom),
                notice: t(".notice", username: @student.username, password: new_password)
  end

  def generate_password
    new_password = generate_memorable_password
    @student.update!(password: new_password)
    redirect_to classroom_path(@classroom),
                notice: t(".notice", username: @student.username, password: new_password)
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:classroom_id])
  end

  def set_student
    @student = @classroom.users.students.find(params[:id])
  end

  def ensure_teacher_or_admin
    redirect_to root_path unless current_user&.teacher_or_admin?
  end

  def student_params
    params.expect(student: %i[username email])
  end

  def generate_memorable_password
    words = %w[Sunset Moonlight Spring Autumn River Glade Mountain Valley]
    numbers = (1..99).to_a
    "#{words.sample}#{numbers.sample}"
  end
end
