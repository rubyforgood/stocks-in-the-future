# frozen_string_literal: true

require "application_system_test_case"

# The menu is a native <details> disclosure, so these click it for real. A request-level
# test cannot tell an open menu from a closed one - the links are in the DOM either way.
class AccountMenuTest < ApplicationSystemTestCase
  MENU = "[data-testid='account-menu']"

  test "a signed-in user can see who they are and sign out from the header" do
    student = create(:student, :with_portfolio, username: "finn")
    sign_in(student)
    visit root_path

    assert_text "finn", count: 1

    within(MENU) do
      assert_no_link "Sign out", visible: true

      find("summary").click

      assert_text "Student"
      click_on "Sign out"
    end

    # Signing out lands on the sign-in page, where the header's Sign in button is
    # deliberately suppressed - it would link to the page you are already on.
    assert_selector "h1", text: "Sign in to your account"
    assert_no_link "Sign in"
  end

  test "escape closes the account menu and returns focus to the trigger" do
    sign_in(create(:student, :with_portfolio))
    visit root_path

    find("#{MENU} summary").click

    assert_selector "#{MENU}[open]"

    find("body").send_keys(:escape)

    assert_no_selector "#{MENU}[open]"
    assert_equal "summary", page.evaluate_script("document.activeElement.tagName.toLowerCase()")
  end

  # The menu holds identity and account actions only. "My portfolio" was a second copy of a row
  # the sidebar already carries, and a destination hidden behind an avatar is not discoverable.
  test "a student reaches their portfolio from the sidebar, not the account menu" do
    student = create(:student, :with_portfolio)
    sign_in(student)
    visit root_path

    find("#{MENU} summary").click
    within(MENU) { assert_no_link "My portfolio" }

    within("nav[aria-label='Main']") { click_on "My portfolio" }

    assert_current_path user_portfolio_path(student, student.portfolio)
  end

  test "an admin signs out from the same menu inside the admin layout" do
    sign_in(create(:admin))
    visit admin_classrooms_path

    within(MENU) do
      find("summary").click

      assert_text "Admin"
      click_on "Sign out"
    end

    assert_selector "h1", text: "Sign in to your account"
  end
end
