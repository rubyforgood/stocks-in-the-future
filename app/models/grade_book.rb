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

  def finalizable?
    grade_entries.all?(&:finalizable?)
  end

  def incomplete?
    !finalizable?
  end
end
