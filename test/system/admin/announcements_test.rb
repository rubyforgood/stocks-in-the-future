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
      # Administrate may use trix-editor for ActionText
      find("trix-editor").set("Admin created this announcement")
      click_on "Create Announcement"

      assert_text "Announcement was successfully created"
      assert_text "New Admin Announcement"
    end

    test "admin can edit announcements" do
      visit admin_announcement_url(@announcement)
      click_on "Edit"

      fill_in "Title", with: "Updated by Admin"
      find("trix-editor").set("Updated content by admin")
      click_on "Update Announcement"

      assert_text "Announcement was successfully updated"
      assert_text "Updated by Admin"
    end

    test "admin can delete announcements" do
      visit admin_announcements_url
      assert_text @announcement.title

      visit admin_announcement_url(@announcement)
      accept_confirm { click_on "Delete", match: :first }

      assert_text "Announcement was successfully destroyed"
    end

    test "non-admin cannot access admin announcements" do
      sign_out @admin
      teacher = create(:teacher)
      sign_in teacher

      visit admin_announcements_url
      # Should be redirected away from admin area
      assert_current_path root_path
      assert_text "Access denied"
    end
  end
end
