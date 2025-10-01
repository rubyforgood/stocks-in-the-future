# frozen_string_literal: true

require "test_helper"

class AnnouncementTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    announcement = Announcement.new(title: "Test Title", content: "Test content")
    assert announcement.valid?
  end

  test "should require title" do
    announcement = Announcement.new(content: "Test content")
    assert_not announcement.valid?
    assert_includes announcement.errors[:title], "can't be blank"
  end

  test "should require content" do
    announcement = Announcement.new(title: "Test Title")
    assert_not announcement.valid?
    assert_includes announcement.errors[:content], "can't be blank"
  end

  test "should validate content length" do
    long_title = "a" * 256
    announcement = Announcement.new(title: long_title, content: "Test content")
    assert_not announcement.valid?
    assert_includes announcement.errors[:title], "is too long (maximum is 255 characters)"
  end

  test "should have rich text content" do
    announcement = Announcement.new(title: "Test", content: "Test content")
    assert_respond_to announcement, :content
    # ActionText creates a rich_text association
    assert_respond_to announcement, :rich_text_content
  end

  test "should create announcement with ActionText content" do
    announcement = Announcement.create!(
      title: "Test with Rich Text",
      content: "<p>This is <strong>bold</strong> text</p>"
    )
    assert_not_nil announcement.content
    assert_equal "<div class=\"trix-content\">\n  <p>This is <strong>bold</strong> text</p>\n</div>\n",
                 announcement.content.to_s
  end

  test "excerpt method should return truncated plain text content" do
    long_content = "This is a very long announcement content that should be truncated when excerpted. " * 5
    announcement = Announcement.create!(title: "Long Content", content: long_content)
    excerpt = announcement.excerpt(limit: 100)
    assert excerpt.length <= 100
    assert excerpt.end_with?("...")
    assert_not_includes excerpt, "<p>"
    assert_includes excerpt, "This is a very long announcement content"
  end

  test "published_at should return created_at" do
    announcement = Announcement.create!(title: "Test", content: "Test content")
    assert_equal announcement.created_at, announcement.published_at
  end

  test "latest scope should return announcements in reverse chronological order" do
    old_announcement = Announcement.create!(title: "Old", content: "Old content", created_at: 1.day.ago)
    new_announcement = Announcement.create!(title: "New", content: "New content")

    latest_announcements = Announcement.latest
    assert_equal new_announcement, latest_announcements.first
    assert_equal old_announcement, latest_announcements.last
  end

  test "current scope should return the most recent announcement" do
    Announcement.create!(title: "Old", content: "Old content", created_at: 1.day.ago)
    new_announcement = Announcement.create!(title: "New", content: "New content")

    assert_equal new_announcement, Announcement.current
  end

  test "current scope should return nil when no announcements exist" do
    assert_nil Announcement.current
  end
end
