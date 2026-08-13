# frozen_string_literal: true

module SoftDeletableFiltering
  extend ActiveSupport::Concern

  included do
    helper_method :discard_filter
  end

  private

  # Which of the three archive tabs is selected, from the query string. `:active`, `:discarded` or `:all`.
  #
  # Exposed to views with `helper_method` because the tabs partial and the empty state both need it, and
  # `AdminHelper#current_discard_filter` was a second copy of these same three lines - one for the view, one
  # for the controller. Two definitions of one rule is how a fourth index comes to read `?archived=1`.
  #
  # The mechanism is deliberately absent from the name of the value: `Classroom` archives with a boolean
  # column and the other three use `discard`, but the tabs, the params and the labels are one convention.
  def discard_filter
    if params[:discarded].present?
      :discarded
    elsif params[:all].present?
      :all
    else
      :active
    end
  end

  # Scopes a resource class based on discard status query parameters
  #
  # @param resource_class [ActiveRecord::Base] The model class to scope
  # @return [ActiveRecord::Relation] Scoped collection based on params
  #
  # Query parameters:
  #   - discarded (any value): Returns only discarded records
  #   - all (any value): Returns all records (including discarded)
  #   - (none): Returns only kept (non-discarded) records
  def scoped_by_discard_status(resource_class)
    case discard_filter
    when :discarded then resource_class.discarded
    when :all       then resource_class.with_discarded
    else                 resource_class.kept
    end
  end
end
