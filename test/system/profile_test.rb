# frozen_string_literal: true

require "application_system_test_case"

# There was no profile page, so the account menu had no "Edit profile" item - design-todo recorded
# both, and that the panel was already built for the item.
class ProfileTest < ApplicationSystemTestCase
  setup do
    classroom = create(:classroom, :with_trading)
    # :nameless, because this test is about a user with no display name set - it types one in and checks
    # the initials change from the username's to the name's.
    @student = create(
      :student, :nameless, :with_portfolio, classroom:, username: "mike",
                                            password: "password"
    )
    @student.reload
    sign_in @student
  end

  test "the account menu leads to the profile, above sign out" do
    visit root_path

    find("[data-testid='account-menu'] summary").click

    items = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("[data-testid='account-menu'] a"))
           .map(function (a) { return a.textContent.trim(); })
    JS

    assert_equal ["Edit profile", "Sign out"], items,
                 "Edit profile goes above Sign out - the destructive action last"

    click_on "Edit profile"

    assert_selector "h1", text: "Your profile"
  end

  test "a display name changes the avatar initials and the menu" do
    visit edit_profile_path

    assert_equal "M", avatar_initials_on_screen, "the username 'mike' should give one initial"

    fill_in "Display name", with: "Ada Lovelace"
    click_on "Save details"

    assert_text "Your profile was updated"
    assert_equal "AL", avatar_initials_on_screen, "two words should give two initials"

    find("[data-testid='account-menu'] summary").click

    assert_selector "[data-testid='account-menu']", text: "Ada Lovelace"
  end

  test "a student changes their own password" do
    visit edit_profile_path

    fill_in "Current password", with: "password"
    fill_in "New password", with: "a-longer-password"
    fill_in "Confirm new password", with: "a-longer-password"
    click_on "Change password"

    assert_text "Your password was changed"
    assert @student.reload.valid_password?("a-longer-password")

    # Still signed in: the page is only reachable authenticated.
    assert_selector "h1", text: "Your profile"
  end

  test "a wrong current password reports on the password form only" do
    visit edit_profile_path

    fill_in "Current password", with: "not-my-password"
    fill_in "New password", with: "a-longer-password"
    fill_in "Confirm new password", with: "a-longer-password"
    click_on "Change password"

    assert_selector "[role=alert]", text: "Current password"

    # Both forms render the same @user, so an unfiltered error block would print this above the
    # details form too.
    assert_equal 1, all("[role=alert]").count
  end

  test "the username is shown but not editable" do
    visit edit_profile_path

    assert_selector "input[readonly][value='mike']"
  end

  def avatar_initials_on_screen
    page.evaluate_script(
      "document.querySelector(\"[data-testid='account-menu'] summary span[aria-hidden]\").textContent.trim()"
    )
  end
end
