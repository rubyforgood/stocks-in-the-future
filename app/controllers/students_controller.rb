class StudentsController < ApplicationController
  before_action :set_student, only: %i[show]

  def show; end

  private

  def set_student
    @student = Student.find(params[:id])
  end
end
