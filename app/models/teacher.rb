# frozen_string_literal: true

class Teacher < User
  attr_accessor :school_id

  has_many :teacher_classrooms, dependent: :destroy
  has_many :classrooms, through: :teacher_classrooms

  before_validation :sync_username_from_email

  def display_name
    name.presence || email&.split("@")&.first || "Teacher"
  end

  private

  def sync_username_from_email
    self.username = email if email.present?
  end
end
