# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to sign in when not authenticated" do
    get root_url
    assert_redirected_to new_user_session_url
  end

  test "should get index when authenticated" do
    sign_in create(:student)
    get root_url
    assert_response :success
  end

  test "index page has expected content when authenticated" do
    sign_in create(:student)
    get root_url
    assert_response :success
    assert_select "title", /StocksInTheFuture/i
  end

  test "index responds with HTML when authenticated" do
    sign_in create(:student)
    get root_url
    assert_response :success
    assert_equal "text/html; charset=utf-8", response.content_type
  end
end
