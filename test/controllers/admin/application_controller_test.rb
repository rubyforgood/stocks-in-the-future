require "test_helper"

class Admin::ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:one)
  end

  test "admin can access admin dashboard" do
    sign_in(@admin)
    get admin_root_path
    assert_response :success
  end

  test "non-admin cannot access admin dashboard" do
    sign_in(@user)
    get admin_root_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to access this page.", flash[:alert]
  end
end
