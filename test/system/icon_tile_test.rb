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

    visit stocks_path

    assert_in_delta FLUSH, body_indent(".tw-card"), TOLERANCE,
                    "the trading floor balance is indented behind its icon tile"
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
