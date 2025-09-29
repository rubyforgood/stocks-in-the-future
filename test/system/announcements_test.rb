# frozen_string_literal: true

require "application_system_test_case"

class AnnouncementsTest < ApplicationSystemTestCase
  setup do
    @announcement = Announcement.create!(
      title: "Test Announcement",
      content: "Test content"
    )
  end

  test "students can view announcements" do
    student = create(:student)
    sign_in student

    visit announcement_url(@announcement)
    assert_text @announcement.title
  end

  test "teachers can view announcements" do
    teacher = create(:teacher)
    sign_in teacher

    visit announcement_url(@announcement)
    assert_text @announcement.title
  end

  test "should display announcement content properly" do
    student = create(:student)
    sign_in student

    visit announcement_url(@announcement)
    assert_text @announcement.title
    # ActionText content should be displayed
    assert_selector ".trix-content"
  end
end
