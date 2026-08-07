# frozen_string_literal: true

require "test_helper"

module Admin
  class ComponentDemoPriceChangeTest < ActionDispatch::IntegrationTest
    # A page of illustrative share prices. Live, it would read as shipped product and its invented figures
    # as real market data.
    test "the price change preview is not reachable outside development" do
      sign_in(create(:admin))

      get price_change_admin_component_demo_index_path

      assert_response :not_found
    end
  end
end
