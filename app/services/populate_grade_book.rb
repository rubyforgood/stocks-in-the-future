# frozen_string_literal: true

# Creates the grade entries for a grade book from its classroom's students.
#
# Until now entries only appeared via seeds or the console, so a real grade book
# started empty with no way to fill it. Entries feed DistributeEarnings, which pays
# students, so this is deliberately additive and repeatable: it only ever inserts
# rows for students that do not have one yet, and never edits an existing entry.
# Running it again after a student joins mid-quarter adds just that student.
#
# Returns the number of entries created, or false if the grade book is completed -
# a completed book has already paid out, so adding an entry would either be ignored
# or double-pay on a re-finalize. Callers need to tell "refused" apart from
# "nothing to add", hence false rather than 0.
class PopulateGradeBook
  def initialize(grade_book)
    @grade_book = grade_book
  end

  def self.execute(...)
    new(...).execute
  end

  def execute
    return false if grade_book.completed?

    students = grade_book.students_missing_entries.to_a

    ActiveRecord::Base.transaction do
      students.each { |student| grade_book.grade_entries.create!(user: student) }
    end

    students.size
  end

  private

  attr_reader :grade_book
end
