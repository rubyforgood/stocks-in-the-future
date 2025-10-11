# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model

  def destroy(*)
    soft_delete_guard
    discard
  end

  def destroy!(*)
    soft_delete_guard
    discard
  end

  def really_destroy!
    ActiveRecord::Base.instance_method(:destroy).bind(self).call
  end

  belongs_to :classroom, optional: true

  # Allow calling `user.school` (used in portfolio view) via the classroom's associated school.
  # This prevents undefined method errors for Student records without directly adding a belongs_to.
  delegate :school, to: :classroom, allow_nil: true

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

  def holding?(stock)
    portfolio&.portfolio_stocks&.exists?(stock_id: stock.id)
  end

  private

  def soft_delete_guard
    return if Rails.env.production?

    raise <<~MSG.squish
      ❌  Hard delete attempted on #{self.class}. Use #discard instead,
      or #really_destroy! if you are ABSOLUTELY sure you need a hard delete.
    MSG
  end
end
