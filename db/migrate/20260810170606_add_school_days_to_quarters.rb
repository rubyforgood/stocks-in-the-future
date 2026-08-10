# frozen_string_literal: true

# The denominator perfect attendance never had.
#
# A teacher typed a day count and then answered a second control saying the student attended every day.
# Nothing reconciled the two, and the bonus followed the flag: in the development seeds one entry carried
# `is_perfect_attendance` with `attendance_days` nil and was paid, and another treated 3 days as perfect.
#
# Nullable on purpose. A quarter that has no figure keeps the stored flag, so nothing that already
# happened changes and no grade book stops working while the number is being collected - see
# `GradeEntry#perfect_attendance?`.
class AddSchoolDaysToQuarters < ActiveRecord::Migration[8.1]
  def change
    add_column :quarters, :school_days, :integer,
               comment: "Teaching days in the quarter. Perfect attendance is derived from it."
  end
end
