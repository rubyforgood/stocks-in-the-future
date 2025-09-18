# frozen_string_literal: true

class Teacher < User
  has_many :teacher_classrooms, dependent: :destroy
  has_many :classrooms, through: :teacher_classrooms

  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP,
                                                message: I18n.t("teachers.validate.email") }
end
