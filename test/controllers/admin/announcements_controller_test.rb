# frozen_string_literal: true

require "test_helper"

module Admin
  class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin)
      sign_in @admin
      @announcement = Announcement.create!(
        title: "Test Announcement",
        content: "Test content"
      )
    end

    test "should get index" do
      get admin_announcements_url
      assert_response :success
    end

    test "should get new" do
      get new_admin_announcement_url
      assert_response :success
    end

    test "should create announcement" do
      assert_difference("Announcement.count") do
        post admin_announcements_url, params: { announcement: { content: "New content", title: "New title" } }
      end

      assert_redirected_to admin_announcement_url(Announcement.last)
    end

    test "should show announcement" do
      get admin_announcement_url(@announcement)
      assert_response :success
    end

    test "should get edit" do
      get edit_admin_announcement_url(@announcement)
      assert_response :success
    end

    test "should update announcement" do
      patch admin_announcement_url(@announcement),
            params: { announcement: { content: "Updated content", title: "Updated title" } }
      assert_redirected_to admin_announcement_url(@announcement)
    end

    test "should destroy announcement" do
      assert_difference("Announcement.count", -1) do
        delete admin_announcement_url(@announcement)
      end

      assert_redirected_to admin_announcements_url
    end

    test "should not create announcement without title" do
      assert_no_difference("Announcement.count") do
        post admin_announcements_url, params: { announcement: { content: "Some content" } }
      end
      assert_response :unprocessable_entity
    end

    test "should not create announcement without content" do
      assert_no_difference("Announcement.count") do
        post admin_announcements_url, params: { announcement: { title: "Some title" } }
      end
      assert_response :unprocessable_entity
    end

    test "non-admin users cannot access admin announcements" do
      sign_out @admin
      teacher = create(:teacher)
      sign_in teacher

      get admin_announcements_url
      assert_response :redirect
      assert_redirected_to root_url
    end
  end
end
