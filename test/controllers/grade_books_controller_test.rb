# frozen_string_literal: true

require "test_helper"

class GradeBooksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @classroom = create(:classroom)
    @teacher = create(:teacher)
    @teacher.classrooms << @classroom
    @student = create(:student, classroom: @classroom)
    @first_quarter = create(:quarter, school_year: @classroom.school_year)
    @second_quarter = create(:quarter, school_year: @classroom.school_year)
    @grade_book = create(:grade_book, classroom: @classroom, quarter: @first_quarter)
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
    assert_redirected_to @student.portfolio_path
  end

  test "teachers cannot finalize a grade book" do
    DistributeEarnings.expects(:execute).never
    sign_in(@teacher)

    post finalize_classroom_grade_book_path(@classroom, @grade_book)
    assert_redirected_to root_path
    @grade_book.reload
    assert_not @grade_book.verified?
  end

  test "finalize runs the DistributeFunds service" do
    DistributeEarnings.expects(:execute).with(@grade_book).once

    sign_in(create(:admin))
    # Fill out all entries to make the grade book finalizable
    @grade_book.grade_entries.each do |entry|
      entry.update!(math_grade: "A", reading_grade: "B", attendance_days: 30)
    end

    post finalize_classroom_grade_book_path(@classroom, @grade_book)

    assert_redirected_to classroom_grade_book_path(@classroom, @grade_book)
    @grade_book.reload
    assert @grade_book.verified?
  end

  test "finalize grade book with incomplete grade entry and no previous quarter" do
    sign_in(create(:admin))

    @grade_book.grade_entries.first.update!(
      math_grade: nil, reading_grade: nil, attendance_days: 30
    )

    post finalize_classroom_grade_book_path(@classroom, @grade_book)

    assert_redirected_to classroom_grade_book_path(@classroom, @grade_book)
    assert_equal "Grade book finalized. Funds have been distributed.", flash[:notice]

    @grade_book.reload
    assert @grade_book.completed?
  end

  test "finalize grade book with complete grade entry and no previous quarter" do
    sign_in(create(:admin))

    @grade_book.grade_entries.first.update!(
      math_grade: "A", reading_grade: "B", attendance_days: 30
    )

    post finalize_classroom_grade_book_path(@classroom, @grade_book)

    assert_redirected_to classroom_grade_book_path(@classroom, @grade_book)
    assert_equal "Grade book finalized. Funds have been distributed.", flash[:notice]

    @grade_book.reload
    assert @grade_book.completed?
  end

  # Scenario 2: Finalize grade book with previous quarter grade book
  test "finalize grade book with incomplete grade entry and previous quarter exists" do
    sign_in(create(:admin))

    # Mark first quarter as completed (acts as previous quarter)
    @grade_book.update!(status: :completed)
    @grade_book.grade_entries.first.update!(
      math_grade: "A", reading_grade: "B", attendance_days: 30
    )

    # Create new grade book for second quarter with incomplete grades
    new_grade_book = create(:grade_book, classroom: @classroom, quarter: @second_quarter)
    create(:grade_entry, grade_book: new_grade_book, user: @student,
                         math_grade: nil, reading_grade: nil, attendance_days: 30)

    post finalize_classroom_grade_book_path(@classroom, new_grade_book)

    assert_redirected_to classroom_grade_book_path(@classroom, new_grade_book)
    assert_equal "Grade book finalized. Funds have been distributed.", flash[:notice]

    new_grade_book.reload
    assert new_grade_book.completed?
  end

  test "finalize grade book with complete grade entry and previous quarter exists" do
    sign_in(create(:admin))

    # Mark first quarter as completed (acts as previous quarter)
    @grade_book.update!(status: :completed)
    @grade_book.grade_entries.first.update!(
      math_grade: "B", reading_grade: nil, attendance_days: 30
    )

    # Create new grade book for second quarter with complete grades
    new_grade_book = create(:grade_book, classroom: @classroom, quarter: @second_quarter)
    create(:grade_entry, grade_book: new_grade_book, user: @student,
                         math_grade: "A", reading_grade: "A", attendance_days: 30)

    post finalize_classroom_grade_book_path(@classroom, new_grade_book)

    assert_redirected_to classroom_grade_book_path(@classroom, new_grade_book)
    assert_equal "Grade book finalized. Funds have been distributed.", flash[:notice]

    new_grade_book.reload
    assert new_grade_book.completed?
  end

  test "does not finalize already completed grade book" do
    sign_in(create(:admin))
    @grade_book.update!(status: :completed)

    post finalize_classroom_grade_book_path(@classroom, @grade_book)

    assert_redirected_to classroom_grade_book_path(@classroom, @grade_book)
    assert_equal "Cannot finalize because it's already completed.", flash[:alert]
  end
end
