# frozen_string_literal: true

class Student < User
  has_many :student_classrooms, dependent: :destroy
  has_many :classrooms, through: :student_classrooms

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
end
