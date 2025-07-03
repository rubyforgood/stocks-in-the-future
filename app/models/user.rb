# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to :classroom, optional: true

  has_one :portfolio, dependent: :destroy
  accepts_nested_attributes_for :portfolio
  has_many :orders, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, uniqueness: true, presence: false, allow_blank: true
  validates :username, presence: true, uniqueness: true
  validates :type, inclusion: { in: %w[User Student Teacher] }

  scope :students, -> { where(type: "Student") }
  scope :teachers, -> { where(type: "Teacher") }
  scope :admins, -> { where(admin: true) }

  def student?
    type == "Student"
  end

  def teacher?
    type == "Teacher"
  end

  def teacher_or_admin?
    teacher? || admin?
  end

  def display_name
    username.presence || email&.split("@")&.first || "User"
  end

  def email_required?
    teacher? || admin?
  end

  def email_changed?
    false
  end
end
