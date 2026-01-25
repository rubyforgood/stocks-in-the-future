# frozen_string_literal: true

require "test_helper"

module Admin
  module V2
    class BaseControllerTest < ActionDispatch::IntegrationTest
      test "admin can access admin v2 dashboard" do
        admin = create(:admin, admin: true)
        sign_in(admin)

        get admin_v2_root_path

        assert_response :success
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
    end
  end
end
