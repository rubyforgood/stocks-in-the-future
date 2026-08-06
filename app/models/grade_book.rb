# frozen_string_literal: true

class GradeBook < ApplicationRecord
  belongs_to :quarter
  belongs_to :classroom
  has_many :grade_entries, dependent: :destroy

  enum :status, {
    draft: "draft",
    verified: "verified",
    completed: "completed"
  }

  # The same student's entry in the previous quarter, keyed by user_id. Improvement earnings are paid
  # by comparing against it, so anything that shows a student what they will earn needs the same
  # lookup DistributeEarnings uses - it lived privately in that service, and a second copy in a view
  # is how a preview drifts from the payout it is previewing.
  #
  # index_by, not group_by: grade_entries is unique on [grade_book_id, user_id], so there is at most
  # one. The service used group_by and then `&.first`, which read as though there might be several.
  #
  # {} covers the first quarter of a school year and a classroom with no grade book last quarter.
  # Both mean "no improvement to pay".
  def previous_entries_by_user_id
    previous_quarter = quarter&.previous
    return {} unless previous_quarter

    previous_book = GradeBook.find_by(classroom: classroom, quarter: previous_quarter)
    return {} unless previous_book

    previous_book.grade_entries.includes(:user).index_by(&:user_id)
  end
end
