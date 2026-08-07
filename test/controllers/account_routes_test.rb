# frozen_string_literal: true

require "test_helper"

# /profile/edit is the account page. Devise's registrations#edit used to be a second one - it could
# not set a display name and demanded the current password before saving anything - and its
# "Delete account" button had never worked.
#
# The unrouted assertions check for 404 rather than a raised RoutingError: this environment sets
# show_exceptions to :rescuable, so the router's error is rendered rather than raised.
class AccountRoutesTest < ActionDispatch::IntegrationTest
  test "the old account page redirects to the profile" do
    sign_in create(:student)

    get "/users/edit"

    assert_redirected_to "/profile/edit"
  end

  test "sign up still renders" do
    get new_user_registration_path

    assert_response :success
    assert_select "h1", text: "Create your account"
  end

  test "sign up still creates an account" do
    assert_difference "User.count", 1 do
      post user_registration_path,
           params: { user: { username: "newcomer", password: "password",
                             password_confirmation: "password" } }
    end
  end

  # It raised "Hard delete attempted ... Use #discard instead", so it returned a 500 rather than
  # deleting anything - and portfolio and orders are `dependent: :destroy`, so a working version
  # would have let a student delete their own money history. Deactivation is an admin action.
  test "there is no self-service account deletion" do
    sign_in create(:student)

    delete "/users"

    assert_response :not_found
  end

  test "the account edit form is not routed either" do
    sign_in create(:student)

    patch "/users", params: { user: { email: "x@example.com" } }

    assert_response :not_found
  end
end
