# frozen_string_literal: true

require "test_helper"

# The component demo is the one admin destination that is not part of the product.
#
# It used to be a purple row in a sidebar section headed `Development`, which put a second meaning into a
# navigation whose colour already means "you are here" - and because the row was hand-rolled it also kept a
# 44px height after NavHelper moved a desktop row to 36px. It did not fit either: the ten product rows are
# 561px in 561px of Chromebook, so the section scrolled the sidebar by 67px. It is a top-bar link now, beside
# `View site`, which is where this app put its other non-product destination for exactly that reason.
#
# Nothing caught any of it, because the guard was `Rails.env.development?` and the suite runs in the test
# environment: the row and the page were invisible to every test in the repo. The guard is `Rails.env.local?`
# now - development and test, not staging or production - so these assertions are possible at all. That is
# half the point of the change.
class DevelopmentOnlyPagesTest < ActionDispatch::IntegrationTest
  setup { sign_in(create(:admin)) }

  test "every row in the admin nav uses the shared row treatment" do
    get admin_root_path

    rows = response.parsed_body.css("nav[aria-label='Admin'] a")

    assert_operator rows.size, :>=, 10, "expected the ten product section rows"
    rows.each do |row|
      assert_includes row["class"].to_s, NavHelper::NAV_ROW_BASE,
                      "the #{row.text.split.join(' ')} row is not on NavHelper's shared base"
    end
  end

  test "the admin nav carries no colour other than the selected state" do
    get admin_root_path

    classes = response.parsed_body.css("nav[aria-label='Admin'] a").map { |row| row["class"].to_s }.join(" ")

    # Every hue in the sidebar is either slate or the brand. A third one competes with the one thing the
    # sidebar's colour means.
    hues = classes.scan(/(?:text|bg|border|outline)-([a-z]+)-\d{2,3}/).flatten.uniq

    assert_equal [], hues - %w[slate sitf],
                 "the admin nav rows carry a hue that is neither slate nor the brand: #{hues.inspect}"
  end

  test "the component demo is a top-bar link, not a sidebar row" do
    get admin_root_path

    assert_response :success
    body = response.parsed_body

    assert_empty body.css("nav[aria-label='Admin'] a").select { |a| a.text.include?("Component demo") },
                 "the component demo is back in the sidebar, which does not fit an eleventh row"
    assert body.css("a[href='#{admin_component_demo_index_path}']").any?,
           "the component demo link is missing from the admin top bar"
  end

  test "no sidebar section is marked while the component demo is open" do
    get admin_component_demo_index_path

    assert_response :success
    selected = response.parsed_body.css("nav[aria-label='Admin'] [aria-current='page']")
      .map { |el| el.text.split.join(" ") }.uniq

    # Dashboard is /admin, which is a prefix of this path - nav_section_active?'s exact: option is what
    # stops it lighting up here, and it is worth pinning from a page outside every section.
    assert_equal [], selected
  end

  test "every component demo page carries the environment banner" do
    user = create(:student, classroom: create(:classroom))

    [admin_component_demo_index_path,
     form_admin_component_demo_index_path,
     admin_component_demo_path(user)].each do |path|
      get path

      assert_response :success
      banner = response.parsed_body.at_css("[data-testid='environment-banner']")

      assert banner, "#{path} has no environment banner"
      assert_includes banner.text, "Test environment",
                      "#{path}: the banner names the environment it is derived from, not a hard-coded one"
      assert_includes banner.text, "not part of the product", "#{path}: the banner says what the page is"

      # A state, not an outcome: the environment is still true in a minute, so this one neither hides itself
      # nor offers to be hidden. flash_dismiss_test asserts the other half of that rule.
      assert_nil banner["data-controller"], "#{path}: the environment banner has no auto-dismiss"
      assert_empty banner.css("button, input[type=submit]"),
                   "#{path}: the environment banner has no dismiss control"
    end
  end

  test "the demo pages are the only place the environment banner appears" do
    get admin_root_path

    assert_response :success
    assert_nil response.parsed_body.at_css("[data-testid='environment-banner']"),
               "a product page carries the demo's environment banner"
  end
end
