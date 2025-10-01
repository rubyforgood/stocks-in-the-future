# frozen_string_literal: true

class Announcement < ApplicationRecord
  has_rich_text :content

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true

  scope :latest, -> { order(created_at: :desc) }

  def self.current
    latest.first
  end

  def excerpt(limit: 150)
    content&.to_plain_text&.truncate(limit) || ""
  end

  def published_at
    created_at # Alias for semantic clarity
  end
end
