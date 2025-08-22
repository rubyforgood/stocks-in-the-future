# frozen_string_literal: true

# app/controllers/grade_books_controller.rb
class GradeBooksController < ApplicationController
  def show
    @classroom = Classroom.find(params[:classroom_id])
    @grade_book = @classroom.grade_books.find(params[:id])
  end
end
