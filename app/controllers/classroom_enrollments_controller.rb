# frozen_string_literal: true

# Manages student enrollments in classrooms
class ClassroomEnrollmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_teacher_or_admin
  before_action :set_classroom
  before_action :set_enrollment, only: %i[destroy unenroll]

  # POST /classrooms/:classroom_id/classroom_enrollments
  def create
    student = Student.find(enrollment_params[:student_id])

    enrollment = student.enroll_in!(
      @classroom,
      primary: enrollment_params[:primary] == "true"
    )

    if enrollment.persisted?
      redirect_to classroom_path(@classroom),
                  notice: "#{student.username} enrolled in #{@classroom.name}"
    else
      redirect_to classroom_path(@classroom),
                  alert: "Failed to enroll student: #{enrollment.errors.full_messages.join(', ')}"
    end
  end

  # DELETE /classrooms/:classroom_id/classroom_enrollments/:id
  def destroy
    student = @enrollment.student
    @enrollment.destroy

    redirect_to classroom_path(@classroom),
                notice: "Removed #{student.username}'s enrollment from #{@classroom.name}"
  end

  # PATCH /classrooms/:classroom_id/classroom_enrollments/:id/unenroll
  def unenroll
    student = @enrollment.student
    @enrollment.unenroll!

    redirect_to classroom_path(@classroom),
                notice: "#{student.username} unenrolled from #{@classroom.name}"
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:classroom_id])
  end

  def set_enrollment
    @enrollment = @classroom.classroom_enrollments.find(params[:id])
  end

  def enrollment_params
    params.expect(classroom_enrollment: %i[student_id primary])
  end
end
