# frozen_string_literal: true

require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = create(:student, username: "mike", password: "password")
  end

  test "requires a signed-in user" do
    get edit_profile_path

    assert_redirected_to new_user_session_path
  end

  test "a student can open their own profile" do
    sign_in @student

    get edit_profile_path

    assert_response :success
    assert_select "h1", text: "Your profile"
  end

  # The regression guard for the bug this page shipped with. User is an STI base, so form_with
  # derives the param key from the record's class: a Student posted student[name] and a Teacher
  # teacher[name], while the controller expects user, and every submit was a 400. A controller test
  # that hand-writes `params: { user: ... }` agrees with the controller rather than the browser, so
  # it cannot catch it - assert the rendered names instead.
  test "the form scopes its fields to user, not to the STI subclass" do
    sign_in @student

    get edit_profile_path

    assert_select "input[name=?]", "user[name]"
    assert_select "input[name=?]", "user[current_password]"
    assert_select "input[name=?]", "student[name]", count: 0
  end

  test "a teacher gets the profile too, with email described as required" do
    teacher = create(:teacher, email: "t@example.com")
    sign_in teacher

    get edit_profile_path

    assert_response :success
    assert_select "input[name=?]", "user[email]"
  end

  # The point of the page: setting a display name must not require proving your password. Devise's
  # registrations#edit does, which is why it was never a usable profile page here.
  test "saving a display name does not require the current password" do
    sign_in @student

    patch profile_path, params: { user: { name: "Mike O'Brien" } }

    assert_redirected_to edit_profile_path
    assert_equal "Mike O'Brien", @student.reload.name
  end

  test "a blank display name falls back to the username" do
    @student.update!(name: "Mike O'Brien")
    sign_in @student

    patch profile_path, params: { user: { name: "" } }

    assert_equal "mike", @student.reload.display_name
  end

  test "the username cannot be changed through the profile" do
    sign_in @student

    patch profile_path, params: { user: { name: "Mike", username: "someone_else" } }

    assert_equal "mike", @student.reload.username
  end

  test "changing a password requires the current one" do
    sign_in @student

    patch password_profile_path,
          params: { user: { current_password: "wrong", password: "newpassword",
                            password_confirmation: "newpassword" } }

    assert_response :unprocessable_content
    assert @student.reload.valid_password?("password"), "the password should not have changed"
  end

  test "a correct current password changes the password and keeps the session" do
    sign_in @student

    patch password_profile_path,
          params: { user: { current_password: "password", password: "newpassword",
                            password_confirmation: "newpassword" } }

    assert_redirected_to edit_profile_path
    assert @student.reload.valid_password?("newpassword")

    # Devise keeps part of the password salt in the session, so without bypass_sign_in the request
    # that changed the password signs you out.
    get edit_profile_path

    assert_response :success
  end

  test "a mismatched confirmation is rejected" do
    sign_in @student

    patch password_profile_path,
          params: { user: { current_password: "password", password: "newpassword",
                            password_confirmation: "different" } }

    assert_response :unprocessable_content
    assert @student.reload.valid_password?("password")
  end
end
