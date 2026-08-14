# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model

  # `dismissals`, plus dismissed?/dismiss!. A dismissal is a fact about a person rather than about a
  # portfolio, which is why it hangs here and not there - the two columns this replaced were on
  # portfolios only because both readers happened to be students.
  include Dismissible

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
  delegate :name, to: :school, prefix: :school, allow_nil: true
  delegate :trading_enabled?, :trading_open?, to: :classroom, allow_nil: true

  has_one :portfolio, dependent: :destroy
  accepts_nested_attributes_for :portfolio
  has_many :orders, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # A blank name is no name. Submitting the optional name field empty stored "" rather than nil, which
  # `display_name` survives because it uses `.presence` - but the column would then hold two different
  # representations of "unset", and anything reaching for `name.nil?` would be wrong for half of them.
  # Also trims, so " Jordan " does not become a name with edges.
  normalizes :name, with: ->(value) { value.strip.presence }

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

  # `name` first: the column has existed all along and nothing ever showed it, so a user had no
  # display name they could set. Falls back to the username, which is what a student signs in with.
  # **Deactivating actually deactivates.** Five confirmations promised "They lose access immediately" and
  # none of them was true: `discard` removed the record from the admin lists and left the login working.
  # Measured before this - a discarded student signed in, got a 303 to root, and the next request was
  # authenticated.
  #
  # Devise's `activatable` hook calls this on every `after_set_user`, not only at sign-in, so a session that
  # is already open ends on the next request rather than surviving until the cookie expires. That matters
  # for the case the copy describes: an administrator deactivating somebody who is using the app right now.
  def active_for_authentication?
    super && !discarded?
  end

  # Which failure message Devise renders. The default is `:inactive`, which reads "Your account has not been
  # activated yet" - true of a confirmable account that was never used, and wrong for one that was turned
  # off. See `devise.failure.deactivated`.
  def inactive_message
    discarded? ? :deactivated : super
  end

  def display_name
    name.presence || username.presence || email&.split("@")&.first || "User"
  end

  def email_required?
    teacher? || admin?
  end

  def email_changed?
    false
  end

  def holding?(stock)
    portfolio&.shares_owned(stock.id)&.positive?
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
