require "test_helper"

module Admin
  class ApplicationControllerTest < ActionDispatch::IntegrationTest
    test "admin can access admin dashboard" do
      admin = create(:user, admin: true)
      sign_in(admin)

      get admin_root_path

      assert_response :success
    end

    test "non-admin cannot access admin dashboard" do
      user = create(:user)
      sign_in(user)

      get admin_root_path

      assert_redirected_to root_path
      assert_equal "You are not authorized to access this page.", flash[:alert]
    end
  end
end
