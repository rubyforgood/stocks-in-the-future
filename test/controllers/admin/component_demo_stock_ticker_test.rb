# frozen_string_literal: true

require "test_helper"

module Admin
  class ComponentDemoStockTickerTest < ActionDispatch::IntegrationTest
    # A page of hypothetical UI carrying invented share prices. Live, it would read as shipped product
    # and its illustrative figures as real market data.
    test "the stock ticker preview is not reachable outside development" do
      sign_in(create(:admin))

      get stock_ticker_admin_component_demo_index_path

      assert_response :not_found
    end
  end
end
