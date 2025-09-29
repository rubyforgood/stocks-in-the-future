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

  test "should show current announcement on home page" do
    sign_in create(:student)

    announcement = Announcement.create!(
      title: "Welcome Students!",
      content: "This is an important announcement for all students."
    )

    get root_url
    assert_response :success
    assert_select "h3", text: "Welcome Students!"
    assert_select "a[href=?]", announcement_path(announcement), text: "Read More"
  end

  test "should show most recent announcement when multiple exist" do
    sign_in create(:student)

    Announcement.create!(
      title: "Old Announcement",
      content: "This is old news.",
      created_at: 2.days.ago
    )

    Announcement.create!(
      title: "Latest News",
      content: "This is the latest announcement."
    )

    get root_url
    assert_response :success
    assert_select "h3", text: "Latest News"
    assert_no_match(/Old Announcement/, response.body)
  end

  test "should show no announcements message when none exist" do
    sign_in create(:student)

    get root_url
    assert_response :success
    assert_select "p", text: "No announcements yet."
  end

  test "should truncate long announcement content" do
    sign_in create(:student)

    long_content = "This is a long announcement content that should be truncated when displayed. " * 5
    Announcement.create!(
      title: "Long Announcement",
      content: long_content
    )

    get root_url
    assert_response :success
    assert_no_match(/#{long_content}/, response.body)
    assert_select "a", text: "Read More"
  end
end
