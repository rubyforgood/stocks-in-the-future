# frozen_string_literal: true

module SoftDeletableFiltering
  extend ActiveSupport::Concern

  private

  # Scopes a resource class based on discard status query parameters
  #
  # @param resource_class [ActiveRecord::Base] The model class to scope
  # @return [ActiveRecord::Relation] Scoped collection based on params
  #
  # Query parameters:
  #   - discarded=1: Returns only discarded records
  #   - all=1: Returns all records (including discarded)
  #   - (none): Returns only kept (non-discarded) records
  def scoped_by_discard_status(resource_class)
    if params[:discarded] == "1"
      resource_class.discarded
    elsif params[:all] == "1"
      resource_class.with_discarded
    else
      resource_class.kept
    end
  end
end
