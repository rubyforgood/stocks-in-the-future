# frozen_string_literal: true

# app/controllers/grade_books_controller.rb
class GradeBooksController < ApplicationController
  def show
    @classroom = Classroom.find(params[:classroom_id])
    @grade_book = @classroom.grade_books.includes(:grade_entries).find(params[:id])
  end

  def update
    @classroom = Classroom.find(params[:classroom_id])
    @grade_book = @classroom.grade_books.find(params[:id])

    grade_entry_params.each do |id, attrs|
      entry = @grade_book.grade_entries.find(id)
      entry.update(attrs)
    end

    redirect_to classroom_grade_book_path(@classroom, @grade_book)
  end

  private

  def grade_entry_params
    params.require(:grade_entries).transform_values do |entry|
      entry.permit(:math_grade, :reading_grade, :attendance_days)
    end
  end
end
