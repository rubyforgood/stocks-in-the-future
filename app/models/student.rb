# frozen_string_literal: true

class Student < User
  # Ensure students have nil email by default (not empty string)
  after_initialize :set_default_email, if: :new_record?

  delegate :path, to: :portfolio, prefix: true, allow_nil: true

  private

  def set_default_email
    self.email = nil if email.blank?
  end
end
