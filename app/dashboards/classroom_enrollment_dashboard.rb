# frozen_string_literal: true

require "administrate/base_dashboard"

class ClassroomEnrollmentDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    student: Field::BelongsTo,
    classroom: Field::BelongsTo,
    enrolled_at: Field::DateTime,
    unenrolled_at: Field::DateTime,
    primary: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    classroom
    enrolled_at
    unenrolled_at
    primary
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    student
    classroom
    enrolled_at
    unenrolled_at
    primary
    created_at
    updated_at
  ].freeze

  def display_resource(enrollment)
    "#{enrollment.classroom.name} - #{enrollment.enrolled_at.strftime('%B %d, %Y')}"
  end
end
