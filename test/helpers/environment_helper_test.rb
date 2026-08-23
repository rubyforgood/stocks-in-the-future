# frozen_string_literal: true

require "test_helper"

class EnvironmentHelperTest < ActionView::TestCase
  include EnvironmentHelper

  test "the ribbon is staging only" do
    assert_not environment_ribbon?
  end

  test "the preview flag shows it outside production, so the chrome can be looked at before it ships" do
    ENV["PREVIEW_STAGING_CHROME"] = "1"
    assert environment_ribbon?
  ensure
    ENV.delete("PREVIEW_STAGING_CHROME")
  end

  test "the preview flag is refused in production, where the ribbon would be a lie" do
    ENV["PREVIEW_STAGING_CHROME"] = "1"
    Rails.env = "production"

    assert_not environment_ribbon?
  ensure
    Rails.env = "test"
    ENV.delete("PREVIEW_STAGING_CHROME")
  end
end
