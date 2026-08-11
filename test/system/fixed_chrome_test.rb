# frozen_string_literal: true

require "application_system_test_case"

# Where the fixed chrome ends is where the content begins - on both halves, with or without the staging
# band, and at 200% text.
#
# **This test exists because of a reported defect.** The admin header was `min-h-16` around a 44px
# trigger inside `py-3`, which measured **69px** while `chrome.css` hardcoded the header at `4rem`. Its
# bottom border therefore landed 5px past the top of the sidebar: "an odd line that goes past the top
# nav, and the horizontal line does not continue". Nothing in the suite could see it, because every
# assertion about this seam was a number - 96 - that both sides happened to agree on until one of them
# grew.
#
# So the assertions here are *relative*: the header's bottom equals the sidebar's top equals the
# content's top. That holds at any height, which is the property that was actually broken.
class FixedChromeTest < ApplicationSystemTestCase
  def in_staging
    Rails.env = "staging"
    yield
  ensure
    Rails.env = "test"
  end

  # `main` differs between the two layouts on purpose - the app side uses margin because its main paints
  # the page background, admin uses padding - so "where content starts" is not the same box.
  # Reads the contract itself - the published offset - rather than guessing which box carries the
  # border. `main` differs between the layouts on purpose: the app side uses margin because its main
  # paints the page background, admin uses padding, so "where content starts" is not the same box.
  GEOMETRY = <<~JS
    (function (navSelector, usesPadding) {
      const px = (name) => parseFloat(getComputedStyle(document.documentElement).getPropertyValue(name));
      const header = document.querySelector(".chrome-header");
      const nav = document.querySelector(navSelector);
      const main = document.querySelector("main");
      const contentBox = usesPadding ? main.firstElementChild : main;
      const border = parseFloat(getComputedStyle(header).borderBottomWidth);
      return {
        offset: Math.round(px("--sitf-header-h") + px("--sitf-ribbon-h")),
        headerPaintedBottom: Math.round(header.getBoundingClientRect().bottom - border),
        navTop: nav ? Math.round(nav.getBoundingClientRect().top) : null,
        contentTop: Math.round(contentBox.getBoundingClientRect().top)
      };
    })(arguments[0], arguments[1])
  JS

  def assert_chrome_seam(nav_selector:, uses_padding:, at:)
    g = page.evaluate_script(GEOMETRY, nav_selector, uses_padding)

    assert_equal g["offset"], g["headerPaintedBottom"],
                 "#{at}: the header paints #{g['headerPaintedBottom'] - g['offset']}px past the offset " \
                 "it publishes, so its rule lands somewhere nothing expects"
    assert_equal g["offset"], g["navTop"],
                 "#{at}: the sidebar starts #{g['navTop'] - g['offset']}px from the header's bottom " \
                 "edge, so the header's rule crosses it"
    assert_equal g["offset"], g["contentTop"],
                 "#{at}: content starts #{g['contentTop'] - g['offset']}px from the header's bottom edge"
  end

  test "admin: header, sidebar and content meet at one line" do
    create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    sign_in create(:admin)
    visit admin_classrooms_path

    assert_chrome_seam(nav_selector: "#admin-navigation", uses_padding: true, at: "admin")

    apply_200_percent_text
    sleep 0.3 # the ResizeObserver publishes on the next frame, and there is no state to wait on
    assert_chrome_seam(nav_selector: "#admin-navigation", uses_padding: true, at: "admin at 200%")
  end

  test "the app side: header, sidebar and content meet at one line" do
    classroom = create(:classroom, :with_trading)
    sign_in create(:student, :with_portfolio, classroom:)
    visit root_path

    assert_chrome_seam(nav_selector: "#main-navigation", uses_padding: false, at: "app")

    apply_200_percent_text
    sleep 0.3
    assert_chrome_seam(nav_selector: "#main-navigation", uses_padding: false, at: "app at 200%")
  end

  test "the staging band moves the whole stack, and the seam still holds" do
    create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    sign_in create(:admin)

    in_staging do
      visit admin_classrooms_path

      ribbon = page.evaluate_script(
        "Math.round(document.querySelector(\"[data-testid='environment-ribbon']\").getBoundingClientRect().height)"
      )
      assert_equal ribbon, page.evaluate_script(
        "Math.round(document.querySelector('.chrome-header').getBoundingClientRect().top)"
      ), "the header should hang directly under the band"

      assert_chrome_seam(nav_selector: "#admin-navigation", uses_padding: true, at: "admin on staging")

      apply_200_percent_text
      sleep 0.3
      assert_chrome_seam(
        nav_selector: "#admin-navigation", uses_padding: true,
        at: "admin on staging at 200%"
      )
    end
  end
end
