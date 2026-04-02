# frozen_string_literal: true

require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    test "index" do
      create(:admin, username: "marceline")
      create(:teacher, username: "bonnibel")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_users_path

      assert_response :success
      assert_select "h3", "Users"
      assert_select "tbody tr", count: User.count
    end

    test "index sorts by username by default" do
      create(:admin, username: "zzz_last")
      create(:admin, username: "aaa_first")
      admin = create(:admin, username: "mmm_admin", admin: true, classroom: nil)
      sign_in(admin)

      get admin_users_path
      rows = css_select("tbody tr td:nth-child(2)").map(&:text).map(&:strip)

      assert_response :success
      assert_equal rows, rows.sort
    end

    test "index sorts descending when direction is desc" do
      create(:admin, username: "zzz_last")
      create(:admin, username: "aaa_first")
      admin = create(:admin, username: "mmm_admin", admin: true, classroom: nil)
      sign_in(admin)

      get admin_users_path, params: { sort: "username", direction: "desc" }
      rows = css_select("tbody tr td:nth-child(2)").map(&:text).map(&:strip)

      assert_response :success
      assert_equal rows, rows.sort.reverse
    end

    test "show" do
      user = create(:admin, username: "finn")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_user_path(user)

      assert_response :success
      assert_select "h2", "finn"
    end

    test "new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_user_path

      assert_response :success
      assert_select "h1", "New User"
    end

    test "edit" do
      user = create(:admin)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_user_path(user)

      assert_response :success
      assert_select "h1", "Edit User"
    end

    test "create" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)
      params = {
        user: {
          username: "bmo",
          email: "bmo@example.com",
          type: "User",
          admin: false,
          password: "Passw0rd",
          password_confirmation: "Passw0rd"
        }
      }

      assert_difference("User.count") do
        post admin_users_path, params: params
      end

      assert_redirected_to admin_user_path(User.last)
      assert_equal "User created successfully.", flash[:notice]
    end

    test "create with invalid params" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)
      params = { user: { username: "", email: "bad@example.com" } }

      assert_no_difference("User.count") do
        post admin_users_path, params: params
      end

      assert_response :unprocessable_content
    end

    test "update" do
      user = create(:admin, username: "original")
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch admin_user_path(user), params: { user: { username: "updated" } }
      user.reload

      assert_redirected_to admin_user_path(user)
      assert_equal "User updated successfully.", flash[:notice]
      assert_equal "updated", user.username
    end

    test "update with invalid params" do
      user = create(:admin)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch admin_user_path(user), params: { user: { username: "" } }

      assert_response :unprocessable_content
    end

    test "non-admin cannot access index" do
      sign_in(create(:teacher))

      get admin_users_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end
  end
end
