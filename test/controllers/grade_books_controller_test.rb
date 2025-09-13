# frozen_string_literal: true

require "test_helper"

class GradeBooksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @classroom = create(:classroom)
    @teacher = create(:teacher)
    @teacher.classrooms << @classroom
    @student = create(:student, classroom: @classroom)
    @grade_book = create(:grade_book, classroom: @classroom)
    create(:grade_entry, grade_book: @grade_book, user: @student)
  end

  test "show" do
    sign_in(@teacher)
    get classroom_grade_book_path(@classroom, @grade_book)
    assert_response :success
  end

  test "update" do
    sign_in(@teacher)
    entry = @grade_book.grade_entries.first
    params = {
      grade_entries: {
        entry.id => {
          math_grade: "A",
          reading_grade: "B",
          attendance_days: 30
        }
      }
    }
    patch classroom_grade_book_path(@classroom, @grade_book), params: params
    assert_redirected_to classroom_grade_book_path(@classroom, @grade_book)

    entry.reload
    assert_equal "A", entry.math_grade
    assert_equal "B", entry.reading_grade
    assert_equal 30, entry.attendance_days
  end

  test "students cannot access grade book" do
    sign_in(@student)
    get classroom_grade_book_path(@classroom, @grade_book)
    assert_redirected_to root_path
  end
end
