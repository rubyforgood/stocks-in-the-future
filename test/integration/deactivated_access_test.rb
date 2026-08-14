# frozen_string_literal: true

require "test_helper"

# Deactivating an account ends its access.
#
# Five confirmations said "They lose access immediately and leave this list" and none of them was true:
# `discard` took the record out of the admin lists and left the login working. Measured before this test
# existed - a discarded student signed in, got a 303 to root, and the next request was authenticated. The
# copy had promised a security outcome for as long as it had existed.
class DeactivatedAccessTest < ActionDispatch::IntegrationTest
  test "a deactivated student cannot sign in" do
    student = create(:student, password: "password123")
    student.discard

    post user_session_path, params: { user: { username: student.username, password: "password123" } }

    # Devise redirects to sign-in for an inactive account rather than rendering a 401, and puts the reason
    # in the flash - `devise.failure.deactivated`, because the default `inactive` reads "not activated yet",
    # which is a different state.
    assert_redirected_to new_user_session_path
    assert_match(/deactivated/i, flash[:alert])

    get root_path

    assert_redirected_to new_user_session_path
  end

  test "an active student still can" do
    student = create(:student, password: "password123")

    post user_session_path, params: { user: { username: student.username, password: "password123" } }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  # The case the confirmation actually describes: somebody using the app when an administrator turns their
  # account off. Devise's `activatable` hook runs on every `after_set_user`, not only at sign-in, so the
  # session ends on the next request rather than surviving until the cookie expires.
  test "a session already open ends on the next request" do
    student = create(:student, password: "password123")
    post user_session_path, params: { user: { username: student.username, password: "password123" } }
    follow_redirect!

    assert_response :success

    student.discard

    get root_path

    assert_redirected_to new_user_session_path
  end

  test "a deactivated teacher cannot sign in either" do
    teacher = create(:teacher, password: "password123")
    teacher.discard

    post user_session_path, params: { user: { username: teacher.username, password: "password123" } }

    assert_redirected_to new_user_session_path
  end
end
