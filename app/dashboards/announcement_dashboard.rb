# frozen_string_literal: true

require "administrate/base_dashboard"

class AnnouncementDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    title: Field::String,
    content: Field::RichText,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    title
    created_at
    updated_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    title
    content
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    title
    content
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
