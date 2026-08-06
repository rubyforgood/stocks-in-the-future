# frozen_string_literal: true

require "test_helper"

module Admin
  class ComponentDemoEarningsSplitTest < ActionDispatch::IntegrationTest
    # The preview is a page of hypothetical UI on the subject of paying students. Live, it would read
    # as shipped product, and its made-up money would read as real money. Same guard the delight
    # previews carried, and the same reason.
    test "the earnings split preview is not reachable outside development" do
      sign_in(create(:admin))

      # The controller raises RoutingError; Rails rescues that into a 404 in an integration test
      # rather than letting it propagate, so the response is what to assert.
      get earnings_split_admin_component_demo_index_path

      assert_response :not_found
    end
  end
end
