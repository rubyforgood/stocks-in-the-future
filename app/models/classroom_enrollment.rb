# frozen_string_literal: true

# Represents a student's enrollment in a classroom, supporting multiple
# enrollments over time with historical tracking.
#
# A student can have multiple enrollment records for the same classroom
# (e.g., enrolled in Fall 2023, then again in Spring 2024), and can be
# enrolled in multiple classrooms simultaneously.
#
# @example Find a student's current enrollments
#   student.classroom_enrollments.current
#
# @example Find a student's enrollment history
#   student.classroom_enrollments.historical
#
# @example Get a student's primary classroom
#   student.primary_enrollment&.classroom
class ClassroomEnrollment < ApplicationRecord
  belongs_to :student, class_name: "Student"
  belongs_to :classroom

  validates :student_id, presence: true
  validates :classroom_id, presence: true
  validates :enrolled_at, presence: true
  validate :unenrolled_at_after_enrolled_at
  validate :only_one_primary_per_student, if: :primary?

  scope :current, -> { where(unenrolled_at: nil) }
  scope :historical, -> { where.not(unenrolled_at: nil) }
  scope :primary_enrollment, -> { where(primary: true) }
  scope :for_student, ->(student) { where(student: student) }
  scope :for_classroom, ->(classroom) { where(classroom: classroom) }

  # Mark this enrollment as the primary enrollment for the student
  # and demote any other primary enrollments
  #
  # @return [self]
  def make_primary!
    transaction do
      ClassroomEnrollment.where(student: student, primary: true)
                        .where.not(id: id)
                        .update_all(primary: false)
      update!(primary: true)
    end
    self
  end

  # Unenroll the student from this classroom
  #
  # @param at [DateTime] when the student was unenrolled (defaults to now)
  # @return [self]
  def unenroll!(at: Time.current)
    update!(unenrolled_at: at, primary: false)
    self
  end

  # Check if this enrollment is currently active
  #
  # @return [Boolean]
  def current?
    unenrolled_at.nil?
  end

  # Check if this enrollment is historical (no longer active)
  #
  # @return [Boolean]
  def historical?
    !current?
  end

  private

  def unenrolled_at_after_enrolled_at
    return if unenrolled_at.blank? || enrolled_at.blank?
    return if unenrolled_at >= enrolled_at

    errors.add(:unenrolled_at, "must be after enrolled_at")
  end

  def only_one_primary_per_student
    return unless student_id.present?

    existing = ClassroomEnrollment.where(student_id: student_id, primary: true)
                                  .where.not(id: id)
                                  .exists?

    errors.add(:primary, "student can only have one primary enrollment") if existing
  end
end
