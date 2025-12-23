# frozen_string_literal: true

require "test_helper"

module AdminV2
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    test "admin can access admin v2 dashboard" do
      admin = create(:admin, admin: true)
      sign_in(admin)

      get admin_v2_root_path

      assert_response :success
      assert_select "h1", "Admin Dashboard"
    end

    test "non-admin cannot access admin v2 dashboard" do
      teacher = create(:teacher)
      sign_in(teacher)

      get admin_v2_root_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "unauthenticated user redirected to sign in" do
      get admin_v2_root_path

      assert_redirected_to new_user_session_path
    end

    test "dashboard shows dual-running information" do
      admin = create(:admin, admin: true)
      sign_in(admin)

      get admin_v2_root_path

      assert_response :success
      assert_select ".bg-blue-50", text: /Dual-Running Mode/
    end
  end
end
