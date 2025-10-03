# frozen_string_literal: true

require "test_helper"

class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:student)
    sign_in @user
    @announcement = Announcement.create!(
      title: "Test Announcement",
      content: "Test content"
    )
  end

  test "should show announcement" do
    get announcement_url(@announcement)
    assert_response :success
  end

  test "students can view announcements" do
    get announcement_url(@announcement)
    assert_response :success
    assert_match @announcement.title, response.body
  end

  test "teachers can view announcements" do
    sign_out @user
    teacher = create(:teacher)
    sign_in teacher

    get announcement_url(@announcement)
    assert_response :success
  end
end
