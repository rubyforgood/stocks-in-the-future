# frozen_string_literal: true

require "application_system_test_case"

# The mobile drawer at 375px. Nothing exercised this before: every system test ran at
# 1400x1400 and the drawer only exists below lg, so both mechanisms were shipped and reworked
# without a single test seeing them (migration.md, Map B, step 0).
#
# These assert position rather than Capybara visibility. An off-canvas panel is moved by a
# transform, and visible? reads display, visibility and opacity - so a closed drawer looks
# visible to Capybara while sitting entirely off screen.
class MobileNavigationTest < ApplicationSystemTestCase
  APP_NAV = "nav[aria-label='Main']"

  test "the app drawer starts closed, opens from the header, and closes again" do
    sign_in(create(:student, :with_portfolio))

    in_phone_viewport do
      visit root_path

      assert_offscreen APP_NAV, "drawer should start off canvas on a phone"

      find("[data-testid='open-navigation']").click

      assert_onscreen APP_NAV, "drawer should be on screen once opened"

      find("[data-testid='close-navigation']").click

      assert_offscreen APP_NAV, "drawer should be off canvas once closed"
    end
  end

  test "the app drawer closes when a destination is chosen" do
    sign_in(create(:student, :with_portfolio))

    in_phone_viewport do
      visit root_path
      find("[data-testid='open-navigation']").click

      within(APP_NAV) { click_on "Transactions" }

      assert_current_path orders_path
      assert_offscreen APP_NAV, "drawer should not stay open over the new page"
    end
  end

  test "the admin drawer opens and closes" do
    sign_in(create(:admin))

    in_phone_viewport do
      visit admin_classrooms_path

      assert_offscreen "#admin-navigation", "admin drawer should start off canvas"

      find("[data-testid='open-navigation']").click

      assert_onscreen "#admin-navigation", "admin drawer should open"

      find("[data-testid='close-navigation']").click

      assert_offscreen "#admin-navigation", "admin drawer should close"
    end
  end

  test "the drawer trigger reports its state, and escape closes it" do
    sign_in(create(:student, :with_portfolio))

    in_phone_viewport do
      visit root_path
      trigger = find("[data-testid='open-navigation']")

      assert_equal "false", trigger["aria-expanded"]

      trigger.click

      assert_equal "true", trigger["aria-expanded"]

      find("body").send_keys(:escape)

      assert_offscreen APP_NAV, "escape should close the drawer"
      assert_equal "false", find("[data-testid='open-navigation']")["aria-expanded"]
    end
  end

  test "the sidebar is not off canvas on a Chromebook" do
    sign_in(create(:student, :with_portfolio))
    visit root_path

    assert_onscreen APP_NAV, "the sidebar is permanent at desktop width"
  end
end
