# frozen_string_literal: true

module UrlHelpers
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end
end
