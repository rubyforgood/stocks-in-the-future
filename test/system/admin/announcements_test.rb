# frozen_string_literal: true

require "application_system_test_case"

module Admin
  class AnnouncementsTest < ApplicationSystemTestCase
    setup do
      @admin = create(:admin)
      sign_in @admin
      @announcement = Announcement.create!(
        title: "Test Announcement",
        content: "Test content"
      )
    end

    test "admin can create announcements through Administrate" do
      visit admin_announcements_url
      assert_text "Announcements"

      click_on "New announcement"

      fill_in "Title", with: "New Admin Announcement"
      find("trix-editor").set("Admin created this announcement")

      assert_difference("Announcement.count", 1) do
        click_on "Create Announcement"

        assert_text "Announcement was successfully created"
      end

      assert_text "New Admin Announcement"
    end

    test "admin can edit announcements" do
      visit admin_announcement_url(@announcement)
      click_on "Edit"

      fill_in "Title", with: "Updated by Admin"
      find("trix-editor").set("Updated content by admin")

      assert_no_difference("Announcement.count") do
        click_on "Update Announcement"

        assert_text "Announcement was successfully updated"
      end

      assert_text "Updated by Admin"
    end

    test "admin can delete announcements" do
      visit admin_announcements_url
      assert_text @announcement.title

      visit admin_announcement_url(@announcement)

      assert_difference("Announcement.count", -1) do
        accept_confirm { click_on "Destroy", match: :first }

        assert_text "Announcement was successfully destroyed"
      end
    end

    test "non-admin cannot access admin announcements" do
      sign_out @admin
      teacher = create(:teacher)
      sign_in teacher

      visit admin_announcements_url
      # Should be redirected away from admin area
      assert_current_path root_path
      # Verify we're on the home page, not the admin interface
      assert_text "WELCOME TO YOUR FINANCIAL JOURNEY!"
    end
  end
end
