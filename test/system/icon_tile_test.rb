# frozen_string_literal: true

require "application_system_test_case"

# design.md has ruled twice that a card's leading icon goes on the title's line, not in a
# full-height column beside the whole body - once on the case-contact card, then again here.
# An items-start icon gutter indents every body line behind it, so the card's content hangs off
# the icon instead of the card edge. On the home page that pushed the cash balance - the one
# number a student is there to read - 77px in from the edge.
#
# Only the rendered box shows that, so this asserts pixels.
class IconTileTest < ApplicationSystemTestCase
  # 20px of card padding plus a 1px border. Anything materially past this is a gutter.
  FLUSH = 21
  TOLERANCE = 2

  setup do
    classroom = create(:classroom, :with_trading)
    @student = create(:student, :with_portfolio, classroom:)
    create(:portfolio_transaction, :deposit, portfolio: @student.portfolio, amount_cents: 100_000)
    sign_in(@student)
  end

  test "a balance sits flush to the card edge, not behind its icon" do
    visit root_path

    assert_in_delta FLUSH, body_indent("section[aria-labelledby='funds-heading']"), TOLERANCE,
                    "the home balance is indented behind its icon tile; the tile belongs on the " \
                    "label's line, not in a column beside the whole card"

    # The trading floor had a second copy of this card, with the same indent bug. It has no card at
    # all now: the figure is a compact line in the page header, because a 217x114 card in the header
    # row pushed the list of things to buy 296px down a 625px viewport. So the assertion there is
    # that no card is carrying a balance, and the figure is in the header.
    visit stocks_path

    assert_no_selector "main .tw-card .tabular-nums:not(td *)",
                       text: /^\$/, wait: 0

    assert_selector "main h1 + p, main div p.tabular-nums", text: /\$/
  end

  test "a step numeral is a tile, not a saturated disc" do
    visit root_path

    numerals = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("ol li span.grid")).map(function (n) {
        const s = getComputedStyle(n);
        return { radius: parseFloat(s.borderRadius), width: Math.round(n.getBoundingClientRect().width),
                 hidden: n.getAttribute("aria-hidden") };
      })
    JS

    assert_equal 4, numerals.length

    numerals.each do |n|
      assert_equal 32, n["width"], "a step numeral is not the 32px tile size"
      assert_in_delta 12, n["radius"], 1,
                      "a step numeral is rounded-full; design.md's tile radius is rounded-xl, and " \
                      "a numeral is slate-900 on a tint rather than white on a brand fill"
      assert_equal "true", n["hidden"], "the ol already conveys order, so the numeral is decorative"
    end
  end

  # A tile's glyph is a UI component: WCAG 1.4.11 asks 3:1. Painting a pixel because
  # getComputedStyle returns oklch() here, and parsing that as RGB reports nonsense.
  test "every icon tile clears 3:1" do
    visit root_path
    page.execute_script(contrast_helpers)

    ratios = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("span.grid svg")).map(function (svg) {
        const tile = svg.parentElement;
        return window.__ratio(getComputedStyle(svg).color, getComputedStyle(tile).backgroundColor);
      })
    JS

    assert_operator ratios.length, :>=, 3, "expected the page's icon tiles to be found"

    ratios.each do |ratio|
      assert_operator ratio, :>=, 3.0, "an icon tile glyph is below 3:1 against its own tint"
    end
  end

  # Two cards side by side in one grid row had their tiles on opposite sides: money_at_work on the
  # left, best_month hung off the right in an `items-start justify-between` row. They also disagreed
  # on tile size (36px vs the home page's 32px), label weight and the gap under the label.
  #
  # design.md: a card's leading icon goes on the title's line. That means the left padding edge.
  test "a card's icon tile sits at its left padding edge, never on the right" do
    create(
      :portfolio_transaction, :deposit,
      portfolio: @student.portfolio, amount_cents: 40_000, reason: "math_earnings"
    )

    [root_path, user_portfolio_path(@student, @student.portfolio)].each do |path|
      visit path

      tiles = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll("main .tw-card")).flatMap(function (card) {
          const tile = card.querySelector("span.grid");
          if (!tile) return [];
          const cb = card.getBoundingClientRect(), tb = tile.getBoundingClientRect();
          return [{ offset: Math.round(tb.left - cb.left),
                    size: Math.round(tb.width),
                    half: Math.round(cb.width / 2) }];
        })
      JS

      assert_operator tiles.length, :>=, 1, "#{path}: expected a card with an icon tile"

      tiles.each do |tile|
        assert_operator tile["offset"], :<, tile["half"],
                        "#{path}: an icon tile is in the right half of its card"
        assert_in_delta FLUSH, tile["offset"], TOLERANCE,
                        "#{path}: an icon tile is not on the card's padding edge"
        assert_equal 32, tile["size"],
                     "#{path}: a tile beside a label is 32px - 36px is for a tile on its own line"
      end
    end
  end

  def body_indent(card_selector)
    page.evaluate_script(<<~JS)
      (function () {
        const card = document.querySelector(#{card_selector.to_json});
        if (!card) return null;
        // The money figure, not the label: the label is the thing that legitimately sits
        // beside the tile, on the header row.
        const figure = card.querySelector(".tabular-nums");
        return Math.round(figure.getBoundingClientRect().left - card.getBoundingClientRect().left);
      })()
    JS
  end

  def contrast_helpers
    <<~JS
      window.__ratio = function (fg, bg) {
        const px = function (css) {
          const c = document.createElement("canvas").getContext("2d");
          c.fillStyle = css; c.fillRect(0, 0, 1, 1);
          return Array.from(c.getImageData(0, 0, 1, 1).data).slice(0, 3);
        };
        const lum = function (rgb) {
          const s = rgb.map(function (v) {
            v = v / 255;
            return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
          });
          return 0.2126 * s[0] + 0.7152 * s[1] + 0.0722 * s[2];
        };
        const a = lum(px(fg)), b = lum(px(bg));
        return Math.round(((Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)) * 100) / 100;
      };
    JS
  end
end
