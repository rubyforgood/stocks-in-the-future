class User < ApplicationRecord
  has_one :portfolio, dependent: :nullify
  has_many :orders, dependent: :nullify
  belongs_to :classroom

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable

  validates :email, uniqueness: true, presence: false, allow_blank: true # standard:disable Rails/UniqueValidationWithoutIndex
  validates :username, presence: true, uniqueness: true

  def email_required?
    false
  end

  def email_changed?
    false
  end
end
