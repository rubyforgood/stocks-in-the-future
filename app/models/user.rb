# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to :classroom

  has_one :portfolio, dependent: :destroy
  has_many :orders, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :email, uniqueness: true, presence: false, allow_blank: true
  validates :username, presence: true, uniqueness: true
  validates :type, inclusion: { in: %w[User Student Teacher] }

  def email_required?
    false
  end

  def email_changed?
    false
  end
end
