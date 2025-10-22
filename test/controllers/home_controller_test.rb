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
    assert_select "a[href=?]", announcement_path(announcement), text: "Read More", count: 0
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

  test "should show full announcement content in scrollable box" do
    sign_in create(:student)

    long_content = "This is a long announcement content that is displayed in full in a scrollable box. " * 5
    Announcement.create!(
      title: "Long Announcement",
      content: long_content
    )

    get root_url
    assert_response :success
    assert_select "h3", text: "Long Announcement"
    assert_select "a", text: "Read More", count: 0
  end

  test "should show positive balance message when student has money" do
    student = create(:student)
    portfolio = student.portfolio

    create(:portfolio_transaction, :deposit, portfolio: portfolio, amount_cents: 5000) # $50.00

    sign_in student
    get root_url

    assert_response :success
    assert_select "span", text: /You have.*\$50\.00.*to invest! Lets Get Trading!/
    assert_select "img[alt='Party popper celebration']"
  end

  test "should show no earnings message when student has zero balance" do
    student = create(:student)
    sign_in student

    get root_url

    assert_response :success
    assert_select "span", text: "Sorry, you don't have any earnings to invest yet"
    assert_no_match(/to invest! Lets Get Trading!/, response.body)
  end

  test "should not show balance message for non-student users" do
    teacher = create(:teacher)
    sign_in teacher

    get root_url

    assert_response :success
    assert_no_match(/You have.*to invest/, response.body)
    assert_no_match(/Sorry, you don't have any earnings/, response.body)
  end
end
