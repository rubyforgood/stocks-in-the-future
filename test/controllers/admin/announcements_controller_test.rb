# frozen_string_literal: true

require "test_helper"

module Admin
  class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin, admin: true)
      sign_in(@admin)

      @announcement = Announcement.create!(
        title: "Test Announcement",
        content: "Test content"
      )
    end

    # Authorization tests

    test "non-admin cannot access index" do
      sign_out(@admin)
      sign_in(create(:teacher))

      get admin_announcements_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "unauthenticated user is redirected to sign in" do
      sign_out(@admin)

      get admin_announcements_path

      assert_redirected_to new_user_session_path
    end

    # Index tests

    test "should get index" do
      get admin_announcements_path

      assert_response :success
    end

    test "index lists all announcements" do
      announcement2 = Announcement.create!(title: "Second Announcement", content: "More content")

      get admin_announcements_path

      assert_response :success
      assert_match @announcement.title, response.body
      assert_match announcement2.title, response.body
    end

    test "index sorts by created_at ascending by default" do
      get admin_announcements_path

      assert_response :success
    end

    test "index sorts by column when sort param is provided" do
      get admin_announcements_path, params: { sort: "title", direction: "asc" }

      assert_response :success
    end

    test "index sorts descending when direction is desc" do
      get admin_announcements_path, params: { sort: "title", direction: "desc" }

      assert_response :success
    end

    # Show tests

    test "should show announcement" do
      get admin_announcement_path(@announcement)

      assert_response :success
      assert_match @announcement.title, response.body
    end

    # New tests

    test "should get new" do
      get new_admin_announcement_path

      assert_response :success
    end

    # Create tests

    test "should create announcement" do
      assert_difference("Announcement.count") do
        post admin_announcements_path, params: {
          announcement: {
            title: "New Announcement",
            content: "New content",
            featured: false
          }
        }
      end

      assert_redirected_to admin_announcement_path(Announcement.last)
      assert_equal "Announcement created successfully.", flash[:notice]
    end

    test "should create featured announcement" do
      assert_difference("Announcement.count") do
        post admin_announcements_path, params: {
          announcement: {
            title: "Featured Announcement",
            content: "Important content",
            featured: true
          }
        }
      end

      assert Announcement.last.featured?
    end

    test "should not create announcement without title" do
      assert_no_difference("Announcement.count") do
        post admin_announcements_path, params: {
          announcement: {
            title: "",
            content: "Some content"
          }
        }
      end

      assert_response :unprocessable_content
    end

    test "should not create announcement without content" do
      assert_no_difference("Announcement.count") do
        post admin_announcements_path, params: {
          announcement: {
            title: "A title",
            content: ""
          }
        }
      end

      assert_response :unprocessable_content
    end

    # Edit tests

    test "should get edit" do
      get edit_admin_announcement_path(@announcement)

      assert_response :success
    end

    # Update tests

    test "should update announcement" do
      patch admin_announcement_path(@announcement), params: {
        announcement: {
          title: "Updated Title"
        }
      }

      assert_redirected_to admin_announcement_path(@announcement)
      assert_equal "Announcement updated successfully.", flash[:notice]
      assert_equal "Updated Title", @announcement.reload.title
    end

    test "should not update announcement with invalid params" do
      patch admin_announcement_path(@announcement), params: {
        announcement: {
          title: ""
        }
      }

      assert_response :unprocessable_content
      assert_equal "Test Announcement", @announcement.reload.title
    end

    # Destroy tests

    test "should destroy announcement" do
      assert_difference("Announcement.count", -1) do
        delete admin_announcement_path(@announcement)
      end

      assert_redirected_to admin_announcements_path
      assert_equal "Announcement deleted successfully.", flash[:notice]
    end

    test "non-admin cannot destroy announcement" do
      sign_out(@admin)
      sign_in(create(:teacher))

      assert_no_difference("Announcement.count") do
        delete admin_announcement_path(@announcement)
      end

      assert_redirected_to root_path
    end
  end
end
