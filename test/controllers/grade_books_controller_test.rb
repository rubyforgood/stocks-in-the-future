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

  test "admins see the flat allotment form" do
    sign_in(create(:admin))

    get classroom_grade_book_path(@classroom, @grade_book)

    assert_response :success
    assert_select "form[action=?]", flat_allotment_classroom_grade_book_path(@classroom, @grade_book)
    assert_select "input[name='flat_allotment_amount']"
  end

  test "the amount field leaves validation to the server" do
    # Browser constraints would reject some amounts with a native popup and let
    # others reach the server, so the same mistake reports two different ways.
    sign_in(create(:admin))

    get classroom_grade_book_path(@classroom, @grade_book)

    assert_response :success
    assert_select "input[name='flat_allotment_amount']:not([min]):not([max]):not([step])"
  end

  test "an invalid amount renders exactly one flash message" do
    sign_in(create(:admin))

    post flat_allotment_classroom_grade_book_path(@classroom, @grade_book),
         params: { flat_allotment_amount: "0" }
    follow_redirect!

    assert_select "#alert", count: 1
  end

  test "a successful allotment renders exactly one flash message" do
    sign_in(create(:admin))

    post flat_allotment_classroom_grade_book_path(@classroom, @grade_book),
         params: { flat_allotment_amount: "2" }
    follow_redirect!

    assert_select "#notice", count: 1
  end

  test "flat allotment reports a failed deposit instead of raising" do
    sign_in(create(:admin))
    DistributeFlatAllotment.stubs(:execute).raises(
      ActiveRecord::RecordInvalid.new(PortfolioTransaction.new)
    )

    assert_no_difference "PortfolioTransaction.count" do
      post flat_allotment_classroom_grade_book_path(@classroom, @grade_book),
           params: { flat_allotment_amount: "5" }
    end

    assert_redirected_to classroom_grade_book_path(@classroom, @grade_book)
    assert_match(/Could not give the flat allotment/, flash[:alert])
  end

  test "a negative amount is rejected by the server, not the browser" do
    sign_in(create(:admin))

    assert_no_difference "PortfolioTransaction.count" do
      post flat_allotment_classroom_grade_book_path(@classroom, @grade_book),
           params: { flat_allotment_amount: "-5" }
    end

    assert_equal "Enter an amount greater than zero to give each student.", flash[:alert]
  end

  test "teachers do not see the flat allotment form" do
    sign_in(@teacher)

    get classroom_grade_book_path(@classroom, @grade_book)

    assert_response :success
    assert_select "form[action=?]", flat_allotment_classroom_grade_book_path(@classroom, @grade_book), count: 0
  end

  test "flat allotment deposits the same amount for every student in the classroom" do
    other_student = create(:student, classroom: @classroom)
    sign_in(create(:admin))

    assert_difference "PortfolioTransaction.count", 2 do
      post flat_allotment_classroom_grade_book_path(@classroom, @grade_book),
           params: { flat_allotment_amount: "5.50" }
    end

    assert_redirected_to classroom_grade_book_path(@classroom, @grade_book)

    [@student, other_student].each do |student|
      transaction = student.portfolio.portfolio_transactions.last

      assert_equal 550, transaction.amount_cents
      assert_equal "deposit", transaction.transaction_type
      assert_equal "administrative_adjustments", transaction.reason
    end
  end

  test "flat allotment pays students who have no grade entry" do
    # The whole point of the feature: grades never arrived, so there is nothing
    # to base earnings on and possibly no grade entries at all.
    @grade_book.grade_entries.destroy_all
    sign_in(create(:admin))

    assert_difference "PortfolioTransaction.count", 1 do
      post flat_allotment_classroom_grade_book_path(@classroom, @grade_book),
           params: { flat_allotment_amount: "3" }
    end

    assert_equal 300, @student.portfolio.portfolio_transactions.last.amount_cents
  end

  test "flat allotment rejects a blank amount" do
    sign_in(create(:admin))

    assert_no_difference "PortfolioTransaction.count" do
      post flat_allotment_classroom_grade_book_path(@classroom, @grade_book),
           params: { flat_allotment_amount: "" }
    end

    assert_equal "Enter an amount greater than zero to give each student.", flash[:alert]
  end

  test "flat allotment rejects a zero or negative amount" do
    sign_in(create(:admin))

    ["0", "-5"].each do |amount|
      assert_no_difference "PortfolioTransaction.count" do
        post flat_allotment_classroom_grade_book_path(@classroom, @grade_book),
             params: { flat_allotment_amount: amount }
      end

      assert_equal "Enter an amount greater than zero to give each student.", flash[:alert]
    end
  end

  test "teachers cannot give a flat allotment" do
    sign_in(@teacher)

    assert_no_difference "PortfolioTransaction.count" do
      post flat_allotment_classroom_grade_book_path(@classroom, @grade_book),
           params: { flat_allotment_amount: "5" }
    end

    assert_redirected_to root_path
  end

  test "students cannot give a flat allotment" do
    sign_in(@student)

    assert_no_difference "PortfolioTransaction.count" do
      post flat_allotment_classroom_grade_book_path(@classroom, @grade_book),
           params: { flat_allotment_amount: "5" }
    end

    assert_redirected_to @student.portfolio_path
  end
end
