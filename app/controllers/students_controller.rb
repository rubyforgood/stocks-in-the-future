# frozen_string_literal: true

class StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_teacher_or_admin
  before_action :set_classroom
  before_action :set_student, except: %i[new create]

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
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @student.update(student_params)
      redirect_to classroom_path(@classroom), notice: t(".notice")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    username = @student.username
    @student.discard
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

    # Redirect if classroom is archived and user is not an admin
    return unless @classroom.archived? && !current_user.admin?

    redirect_to root_path, alert: "This classroom has been archived and is no longer accessible."
  end

  def set_student
    @student = @classroom.users.students.kept.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to classroom_path(@classroom), alert: t("students.not_found")
  end

  def student_params
    params.expect(student: %i[username email])
  end

  def generate_memorable_password
    MemorablePasswordGenerator.generate
  end
end
