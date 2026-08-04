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
end
