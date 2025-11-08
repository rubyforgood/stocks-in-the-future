# frozen_string_literal: true

class Student < User
  has_many :student_classrooms, dependent: :destroy
  has_many :classrooms, through: :student_classrooms
  validate :classroom_must_exist

  # Ensure students have nil email by default (not empty string)
  after_initialize :set_default_email, if: :new_record?
  after_create :ensure_portfolio

  delegate :path, to: :portfolio, prefix: true, allow_nil: true

  private

  def set_default_email
    self.email = nil if email.blank?
  end

  def ensure_portfolio
    create_portfolio!(current_position: 0) if portfolio.blank?
  end

  def classroom_must_exist
    return if classroom_id.blank?

    errors.add(:classroom, "can't be blank") unless Classroom.exists?(classroom_id)
  end
end
