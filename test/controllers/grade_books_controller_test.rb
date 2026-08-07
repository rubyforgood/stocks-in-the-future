# frozen_string_literal: true

require "test_helper"

class GradeBooksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @classroom = create(:classroom)
    @teacher = create(:teacher)
    @teacher.classrooms << @classroom
    @student = create(:student, classroom: @classroom)
    @first_quarter = @classroom.school_year.quarters.find_by!(number: 1)
    @second_quarter = @classroom.school_year.quarters.find_by!(number: 2)
    @grade_book = @classroom.grade_books.find_by!(quarter: @first_quarter)
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

  test "finalize grade book with incomplete grade entry (empty string) and no previous quarter" do
    sign_in(create(:admin))

    @grade_book.grade_entries.first.update!(
      math_grade: "", reading_grade: "", attendance_days: 30
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
    new_grade_book = @classroom.grade_books.find_by!(quarter: @second_quarter)
    create(
      :grade_entry, grade_book: new_grade_book, user: @student,
                    math_grade: nil, reading_grade: nil, attendance_days: 30
    )

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
    new_grade_book = @classroom.grade_books.find_by!(quarter: @second_quarter)
    create(
      :grade_entry, grade_book: new_grade_book, user: @student,
                    math_grade: "A", reading_grade: "A", attendance_days: 30
    )

    post finalize_classroom_grade_book_path(@classroom, new_grade_book)

    assert_redirected_to classroom_grade_book_path(@classroom, new_grade_book)
    assert_equal "Grade book finalized. Funds have been distributed.", flash[:notice]

    new_grade_book.reload
    assert new_grade_book.completed?
  end

  test "finalize grade book with complete grade entry and previous quarter exists (empty string)" do
    sign_in(create(:admin))

    # Mark first quarter as completed (acts as previous quarter)
    @grade_book.update!(status: :completed)
    @grade_book.grade_entries.first.update!(
      math_grade: "", reading_grade: "", attendance_days: 30
    )

    # Create new grade book for second quarter with complete grades
    new_grade_book = @classroom.grade_books.find_by!(quarter: @second_quarter)
    create(
      :grade_entry, grade_book: new_grade_book, user: @student,
                    math_grade: "A", reading_grade: "A", attendance_days: 30
    )

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

  # The second quarter's grade book has no entries, so it is the empty case setup
  # does not cover.
  test "a teacher can populate an empty grade book" do
    sign_in(@teacher)
    empty_grade_book = @classroom.grade_books.find_by!(quarter: @second_quarter)

    post populate_classroom_grade_book_path(@classroom, empty_grade_book)

    assert_redirected_to classroom_grade_book_path(@classroom, empty_grade_book)
    assert_equal "Added 1 student to this grade book.", flash[:notice]
    assert_equal [@student.id], empty_grade_book.grade_entries.reload.pluck(:user_id)
  end

  test "populating twice adds nothing the second time" do
    sign_in(@teacher)
    empty_grade_book = @classroom.grade_books.find_by!(quarter: @second_quarter)
    post populate_classroom_grade_book_path(@classroom, empty_grade_book)

    assert_no_changes -> { GradeEntry.count } do
      post populate_classroom_grade_book_path(@classroom, empty_grade_book)
    end

    assert_equal "Every student in this class already has a row.", flash[:notice]
  end

  test "students cannot populate a grade book" do
    sign_in(@student)

    assert_no_changes -> { GradeEntry.count } do
      post populate_classroom_grade_book_path(@classroom, @grade_book)
    end

    assert_redirected_to @student.portfolio_path
  end

  test "populate refuses a completed grade book" do
    sign_in(@teacher)
    empty_grade_book = @classroom.grade_books.find_by!(quarter: @second_quarter)
    empty_grade_book.completed!

    assert_no_changes -> { GradeEntry.count } do
      post populate_classroom_grade_book_path(@classroom, empty_grade_book)
    end

    assert_equal "This grade book is complete, so students cannot be added to it.", flash[:notice]
  end

  test "populate reports the number of students added" do
    sign_in(@teacher)
    create_list(:student, 2, classroom: @classroom)
    empty_grade_book = @classroom.grade_books.find_by!(quarter: @second_quarter)

    post populate_classroom_grade_book_path(@classroom, empty_grade_book)

    assert_equal "Added 3 students to this grade book.", flash[:notice]
  end
end
