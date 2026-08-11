# frozen_string_literal: true

# app/controllers/grade_books_controller.rb
class GradeBooksController < ApplicationController
  before_action :set_classroom_and_grade_book
  before_action :authorize_grade_book
  def show; end

  def update
    # **A finalized book's entries are not writable.** Only `finalize` used to check this, and the view
    # simply stopped rendering the inputs - so the endpoint accepted a PATCH against a completed book and
    # rewrote it. Measured before this guard: a grade moved C to A, days 3 to 40 and the perfect-attendance
    # flag to true on a book that had already paid out. The money did not move, which is the worse half:
    # the record and the ledger then disagree, and every figure on the page is derived from the record.
    #
    # An admin can reopen the book to correct it, which is a deliberate door rather than an unlocked one.
    if @grade_book.completed?
      return redirect_to classroom_grade_book_path(@classroom, @grade_book),
                         alert: t(".completed")
    end

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

  # PopulateGradeBook returns false when it refuses (completed book) and otherwise a
  # count, so 0 has to be told apart from false before anything reads it as a number.
  def populate
    created = PopulateGradeBook.execute(@grade_book)

    notice = if created == false
               t(".completed")
             elsif created.zero?
               t(".none_added")
             else
               t(".notice", count: created)
             end

    redirect_to classroom_grade_book_path(@classroom, @grade_book), notice: notice
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

  # Returns a finalized book to editable so it can be corrected. **It does not touch the money.** What was
  # paid stays paid; finalizing again deposits only the difference between what the corrected grades owe and
  # what this book has already paid.
  #
  # `draft`, not `verified`: verified means "checked and ready to pay", and a book being corrected is
  # neither. It also puts the book back through the same path a new one takes.
  def reopen
    if @grade_book.completed?
      @grade_book.draft!
      redirect_to classroom_grade_book_path(@classroom, @grade_book), notice: t(".notice")
    else
      redirect_to classroom_grade_book_path(@classroom, @grade_book), alert: t(".not_completed")
    end
  end

  private

  def authorize_grade_book
    authorize @grade_book
  end

  def set_classroom_and_grade_book
    @classroom = Classroom.find(params.expect(:classroom_id))
    @grade_book = @classroom.grade_books.includes(grade_entries: :user).find(params.expect(:id))

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
