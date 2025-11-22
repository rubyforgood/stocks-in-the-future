# frozen_string_literal: true

class Student < User
  validates :classroom, presence: true
  has_many :enrollments, dependent: :destroy
  has_many :classrooms, through: :enrollments

  # Ensure students have nil email by default (not empty string)
  after_initialize :set_default_email, if: :new_record?
  after_create :ensure_portfolio

  after_create :create_enrollment_for_classroom

  delegate :path, to: :portfolio, prefix: true, allow_nil: true

  private

  def set_default_email
    self.email = nil if email.blank?
  end

  def ensure_portfolio
    create_portfolio!(current_position: 0) if portfolio.blank?
  end

  def create_enrollment_for_classroom
    # Avoid duplicates
    enrollments.find_or_create_by!(classroom_id: classroom_id) if classroom_id.present?
  end
end
