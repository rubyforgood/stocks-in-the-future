# frozen_string_literal: true

require "application_system_test_case"

# Measured spacing, not class names.
#
# The gap under a header was reported wrong three times on this branch, and each time reading
# the classes said it was correct. It was not: pb-5 stacked on mb-6 under the page title; py-4
# stacked on p-5 inside the card; and a 40px CTA in an items-start row left 8px of dead space
# below a 32px h1, so a header that read as mb-6 rendered a 32px gap. Only the rendered geometry
# shows any of that, so these assert pixels.
class SpacingTest < ApplicationSystemTestCase
  TOLERANCE = 2

  # design.md: the header block is mb-6 (24px), and nothing else.
  HEADER_GAP = 24

  # A card's header rule gets equal padding either side - 16px, as Stripe's Box and Primer's
  # Box.Header use - rather than the header's py-4 stacking on a full p-5 body.
  CARD_SEAM = 32

  def distance(from_selector, to_selector)
    page.evaluate_script(<<~JS)
      (function () {
        const a = document.querySelector(#{from_selector.to_json});
        const b = document.querySelector(#{to_selector.to_json});
        if (!a || !b) return null;
        return Math.round(b.getBoundingClientRect().top - a.getBoundingClientRect().bottom);
      })()
    JS
  end

  test "a title-only page header leaves 24px above the content" do
    sign_in(create(:admin))
    visit admin_users_path

    gap = distance("main h1", ".tw-card")

    assert_not_nil gap, "expected an h1 and a card on the admin users index"
    assert_in_delta HEADER_GAP, gap, TOLERANCE,
                    "title to card measured #{gap}px; a 40px action beside a 32px h1 in an " \
                    "items-start row is the usual cause"
  end

  test "a card header leaves 32px between its title and the content" do
    sign_in(create(:admin))
    visit admin_stock_path(create(:stock))

    gap = page.evaluate_script(<<~JS)
      (function () {
        const head = document.querySelector("section.tw-card > header");
        if (!head) return null;
        const body = head.nextElementSibling;
        const title = head.querySelector("h2");
        const first = body.firstElementChild || body;
        return Math.round(first.getBoundingClientRect().top - title.getBoundingClientRect().bottom);
      })()
    JS

    assert_not_nil gap, "expected a titled card on the admin stock page"
    assert_in_delta CARD_SEAM, gap, TOLERANCE,
                    "card header to content measured #{gap}px; the header's padding stacking " \
                    "on a full p-5 body is the usual cause"
  end
  # The nav is the thing most likely to grow past a short viewport: someone adds a section and
  # nobody notices, because the default test window is 1400px tall and no real screen is. Ten
  # admin links at 44px with 24px section gaps measured 636px against 561px of available height
  # and scrolled; at 36px they measure 561px and do not.
  test "the admin sidebar fits a Chromebook without scrolling" do
    sign_in(create(:admin))

    in_chromebook_viewport do
      visit admin_root_path

      overflow = page.evaluate_script(<<~JS)
        (function () {
          const nav = document.querySelector("#admin-navigation");
          if (!nav) return null;
          return nav.scrollHeight - nav.clientHeight;
        })()
      JS

      assert_not_nil overflow, "expected the admin sidebar to be present"
      assert overflow <= 0,
             "the admin sidebar overflows a 1366x768 Chromebook by #{overflow}px; a nav row is " \
             "36px at lg, so this usually means rows or sections were added or loosened"
    end
  end
  # Admin tables hand-wrote their cell padding as px-3 py-4 while their headers used the shared
  # table-header-cell at px-4 py-3, so every column's header text sat 4px off its own data. Both
  # sides use the shared classes now; this asserts a column actually lines up.
  test "a table header lines up with its column" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.portfolio.portfolio_transactions.create!(
      amount_cents: 500, transaction_type: :deposit,
      reason: :math_earnings
    )
    sign_in(create(:admin))
    visit admin_portfolio_transactions_path

    offset = page.evaluate_script(<<~JS)
      (function () {
        const th = document.querySelector("thead th");
        const td = document.querySelector("tbody td");
        if (!th || !td) return null;
        return Math.round(th.getBoundingClientRect().left - td.getBoundingClientRect().left);
      })()
    JS

    assert_not_nil offset, "expected a table with a header and a body row"
    assert_in_delta 0, offset, 1,
                    "the header is #{offset}px off its column; admin tables writing their own " \
                    "cell padding instead of the shared table-* classes is the usual cause"
  end
  # The layout owns the gutter between the sidebar and the content. When a page added its own
  # horizontal padding on top of main's, the app rendered 48px against admin's 24px - and 53px on
  # home, where a narrower max-width let mx-auto centre the column and widen it further.
  GUTTER = 24

  test "the gutter between sidebar and content is the same on both sides" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))

    sign_in(create(:admin))
    visit admin_users_path

    assert_in_delta GUTTER, sidebar_to_content_gutter(".tw-card"), 2,
                    "admin content gutter is off"

    sign_out(:user)
    sign_in(student)
    visit root_path

    assert_in_delta GUTTER, sidebar_to_content_gutter("section.tw-card"), 2,
                    "app content gutter is off; a page adding its own px on top of main's, or a " \
                    "max-width narrow enough for mx-auto to centre it, are the usual causes"
  end

  def sidebar_to_content_gutter(card_selector)
    page.evaluate_script(<<~JS)
      (function () {
        const nav = document.querySelector("nav[aria-label='Main'], #admin-navigation");
        const card = document.querySelector(#{card_selector.to_json});
        if (!nav || !card) return null;
        return Math.round(card.getBoundingClientRect().left - nav.getBoundingClientRect().right);
      })()
    JS
  end
end
