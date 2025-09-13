# frozen_string_literal: true

# app/controllers/grade_books_controller.rb
class GradeBooksController < ApplicationController
  before_action :ensure_teacher_or_admin
  before_action :set_classroom_and_gradebook
  def show; end

  def update
    grade_entry_params.each do |id, attrs|
      entry = @grade_book.grade_entries.find(id)
      entry.update(attrs)
    end

    redirect_to classroom_grade_book_path(@classroom, @grade_book)
  end

  def finalize
    if @grade_book.incomplete?
      redirect_to classroom_grade_book_path(@classroom, @grade_book),
                  alert: t(".incomplete")
    else
      @grade_book.verified!
      DistributeEarnings.execute(@grade_book)
      redirect_to classroom_grade_book_path(@classroom, @grade_book),
                  notice: t(".notice")
    end
  end

  private

  def set_classroom_and_gradebook
    @classroom = Classroom.find(params[:classroom_id])
    @grade_book = @classroom.grade_books.find(params[:id])
  end

  def grade_entry_params
    params.require(:grade_entries).transform_values do |entry|
      entry.permit(:math_grade, :reading_grade, :attendance_days)
    end
  end
end
