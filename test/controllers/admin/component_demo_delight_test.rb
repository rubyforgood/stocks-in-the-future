# frozen_string_literal: true

require "test_helper"

module Admin
  class ComponentDemoDelightTest < ActionDispatch::IntegrationTest
    # The preview is a page of hypothetical UI with hard-coded figures. Live, it would read as
    # shipped product, and its made-up money would read as real money.
    test "the delight preview is not reachable outside development" do
      sign_in(create(:admin))

      # The controller raises RoutingError; Rails rescues that into a 404 in an integration test
      # rather than letting it propagate, so the response is what to assert.
      get delight_admin_component_demo_index_path

      assert_response :not_found
    end
  end
end
