# frozen_string_literal: true

require "application_system_test_case"

# A flash banner is as wide as the page it sits above, and starts on the same edge.
#
# It was neither. `layouts/_flash` rendered as a bare child of <main>, which has no max-width, while
# home, stock#show, portfolio and every admin page wrap themselves in `mx-auto max-w-7xl`. So the
# banner spanned main's whole content box and the cards under it stopped at 1280px: at 1920px the
# "Signed in successfully" notice measured 1601px against cards of 1280px, 321px wider and starting
# 161px to their left. Admin was the same split, 1616px against 1280px.
#
# Nothing showed below about 1584px, which is where main's content box stops exceeding max-w-7xl -
# so every existing test width (1400, 1366, 375) measured a perfect match. That is why this needs a
# viewport wider than the suite's default, and why WIDE is the point of the file rather than a
# detail of it.
#
# The fix is structural: the content column moved into both layouts, around the flash *and* the
# yield, so the two cannot disagree. Constraining the flash on its own would have inverted the bug
# on the trading floor, orders, classrooms and classroom#show, which spanned full width.
class FlashWidthTest < ApplicationSystemTestCase
  WIDE = [1920, 1080].freeze

  # The flash, and the widest real block beside it. sr-only elements are skipped: admin puts a
  # visually hidden <h1> directly after the flash, and it measures 1px, so "the next sibling" would
  # compare the banner against nothing.
  def flash_and_content
    page.evaluate_script(<<~JS)
      (function () {
        const flash = document.querySelector("#notice, #alert");
        if (!flash) return null;
        const box = function (el) {
          const b = el.getBoundingClientRect();
          return [Math.round(b.left), Math.round(b.width)];
        };
        let widest = null, who = "";
        Array.from(flash.parentElement.children).forEach(function (el) {
          if (el === flash) return;
          const b = el.getBoundingClientRect();
          if (b.width <= 1 || b.height <= 1) return;
          if (!widest || b.width > widest[1]) { widest = box(el); who = el.tagName.toLowerCase() + "." + String(el.className).slice(0, 30); }
        });
        return { flash: box(flash), content: widest, who: who };
      })()
    JS
  end

  def assert_flash_matches_content(label)
    m = flash_and_content

    assert m, "#{label}: no flash on screen to measure"
    assert m["content"], "#{label}: flash is on screen but nothing beside it to compare against"

    assert_equal m["content"][1], m["flash"][1],
                 "#{label}: the banner is #{m['flash'][1]}px and the page below it " \
                 "(#{m['who']}) is #{m['content'][1]}px. A flash is a bare child of <main> again, " \
                 "outside the content column."
    assert_equal m["content"][0], m["flash"][0],
                 "#{label}: the banner starts at x=#{m['flash'][0]} and the page below it at " \
                 "x=#{m['content'][0]}."
  end

  def sign_in_through_the_form(username)
    visit new_user_session_path
    fill_in "Username", with: username
    fill_in "Password", with: "Passw0rd"
    click_on "Sign in"
    assert_text "Signed in successfully"
  end

  # The reported bug, at the width it appears and at one where it never did - a regression that only
  # reintroduces the wide case would otherwise pass.
  test "the sign-in banner matches the page on a wide screen" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:, username: "widecheck")
    student.reload

    resize_window_to(*WIDE)
    sign_in_through_the_form("widecheck")
    assert_flash_matches_content("home at 1920")
  ensure
    resize_window_to(*DEFAULT_SIZE)
  end

  test "the sign-in banner matches the page on a Chromebook" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:, username: "chromecheck")
    student.reload

    in_chromebook_viewport do
      sign_in_through_the_form("chromecheck")
      assert_flash_matches_content("home at 1366")
    end
  end

  # Admin is the same product and had the same split, so it gets the same assertion. An announcement
  # is deleted because that redirects to an index carrying a notice, which is the only way to get a
  # real flash onto an admin page.
  test "an admin banner matches the page on a wide screen" do
    Announcement.create!(title: "Notice", content: "Body text for the announcement.")
    sign_in create(:admin)

    resize_window_to(*WIDE)
    visit admin_announcements_path
    accept_confirm { click_on "Delete", match: :first }
    assert_selector "#notice"
    assert_flash_matches_content("admin announcements at 1920")
  ensure
    resize_window_to(*DEFAULT_SIZE)
  end
end
