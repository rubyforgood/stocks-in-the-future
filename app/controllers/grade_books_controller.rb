# frozen_string_literal: true

# app/controllers/grade_books_controller.rb
class GradeBooksController < ApplicationController
  before_action :set_classroom_and_grade_book
  before_action :authorize_grade_book
  def show; end

  def update
    GradeEntry.transaction do
      grade_entry_params.each do |id, attrs|
        entry = @grade_book.grade_entries.find(id)
        entry.update!(attrs)
      end
    end

    @grade_book.grade_entries.reload

    respond_to do |format|
      format.html { redirect_to classroom_grade_book_path(@classroom, @grade_book), notice: t(".notice") }
      format.turbo_stream
    end
  end

  def finalize
    if @grade_book.completed?
      redirect_to classroom_grade_book_path(@classroom, @grade_book),
                  alert: t(".already_completed")
    else
      @grade_book.verified!
      DistributeEarnings.execute(@grade_book)
      redirect_to classroom_grade_book_path(@classroom, @grade_book),
                  notice: t(".notice")
    end
  end

  private

  def authorize_grade_book
    authorize @grade_book
  end

  def set_classroom_and_grade_book
    @classroom = Classroom.find(params[:classroom_id])
    @grade_book = @classroom.grade_books.includes(grade_entries: :user).find(params[:id])

    # Redirect if classroom is archived and user is not an admin
    return unless @classroom.archived? && !current_user.admin?

    redirect_to root_path, alert: t("classrooms.archived.alert")
  end

  def grade_entry_params
    params.require(:grade_entries).transform_values do |entry|
      entry.permit(:math_grade, :reading_grade, :attendance_days, :is_perfect_attendance)
    end
  end
end
