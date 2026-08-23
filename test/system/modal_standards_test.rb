# frozen_string_literal: true

require "application_system_test_case"

# Both modals, measured against the design system.
#
# Reported as two cards in the buy modal whose text was off-palette and probably failing contrast.
# Those two panels had been neutralised already, but sweeping both modals found they agreed on almost
# nothing else: two scrims (black/70 and slate-500/75), two panel surfaces (rounded-2xl/shadow-2xl
# and rounded-lg/shadow-xl), two title treatments (h2 text-2xl font-bold centred and h3 text-lg
# font-medium), and an input at border-2 border-slate-500 text-lg against a slate-300 token.
#
# Contrast is measured by painting each colour into a canvas and reading the pixel. getComputedStyle
# returns oklch() in this browser, and reading its three numbers as if they were RGB reports
# slate-600 on slate-50 as 1.05:1 - which is how an earlier version of this audit invented five
# failures that did not exist.
class ModalStandardsTest < ApplicationSystemTestCase
  CONTROL_RADIUS = "8px"
  PANEL_RADIUS = "16px"

  def contrast_failures(root_selector)
    page.evaluate_script(<<~JS)
      (function () {
        const root = document.querySelector(#{root_selector.to_json});
        if (!root) return ["ROOT NOT FOUND"];
        const ctx = document.createElement("canvas").getContext("2d");
        function toRgb(c) {
          ctx.clearRect(0, 0, 1, 1);
          ctx.fillStyle = c;
          ctx.fillRect(0, 0, 1, 1);
          const d = ctx.getImageData(0, 0, 1, 1).data;
          return [d[0], d[1], d[2]];
        }
        function lum(c) {
          const f = toRgb(c).map(v => {
            v /= 255;
            return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
          });
          return 0.2126 * f[0] + 0.7152 * f[1] + 0.0722 * f[2];
        }
        function bgOf(el) {
          let n = el;
          while (n) {
            const c = getComputedStyle(n).backgroundColor;
            if (c && c !== "rgba(0, 0, 0, 0)" && c !== "transparent") return c;
            n = n.parentElement;
          }
          return "rgb(255, 255, 255)";
        }
        const out = [];
        root.querySelectorAll("*").forEach(el => {
          const hasText = Array.from(el.childNodes).some(
            n => n.nodeType === 3 && n.textContent.trim().length > 1
          );
          if (!hasText || !el.getClientRects().length) return;
          const s = getComputedStyle(el);
          const l1 = lum(s.color), l2 = lum(bgOf(el));
          const ratio = (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
          const size = parseFloat(s.fontSize);
          const large = size >= 24 || (size >= 18.66 && parseInt(s.fontWeight, 10) >= 700);
          if (ratio < (large ? 3.0 : 4.5)) {
            out.push(ratio.toFixed(2) + ":1 at " + Math.round(size) + "px - " +
              el.textContent.trim().replace(/\\s+/g, " ").slice(0, 30));
          }
        });
        return out;
      })()
    JS
  end

  def shell_of(scrim_selector, panel_selector)
    page.evaluate_script(<<~JS)
      (function () {
        const scrim = document.querySelector(#{scrim_selector.to_json});
        const panel = document.querySelector(#{panel_selector.to_json});
        if (!scrim || !panel) return null;
        const title = panel.querySelector("h1, h2, h3, h4");
        const close = panel.querySelector("button [class*='sr-only'], button span.sr-only");
        const closeBtn = close ? close.closest("button") : null;
        const ts = title ? getComputedStyle(title) : null;
        return {
          scrim: getComputedStyle(scrim).backgroundColor,
          panelRadius: getComputedStyle(panel).borderTopLeftRadius,
          titleTag: title ? title.tagName : null,
          titleSize: ts ? ts.fontSize : null,
          titleWeight: ts ? ts.fontWeight : null,
          closeRadius: closeBtn ? getComputedStyle(closeBtn).borderTopLeftRadius : null,
          closeTarget: closeBtn
            ? Math.round(Math.min(closeBtn.getBoundingClientRect().width,
                                  closeBtn.getBoundingClientRect().height))
            : null
        };
      })()
    JS
  end

  def open_buy_modal
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    create(:stock, ticker: "KO", company_name: "Coca-Cola Company", price_cents: 15_000)
    sign_in(student)

    visit stocks_path
    within("tr", text: "Coca-Cola") { click_on "Buy" }
    assert_text "Number of shares"
  end

  test "the buy modal clears AA at every step" do
    open_buy_modal

    assert_empty contrast_failures("#modal_overlay")

    fill_in "Number of shares", with: 2
    click_on "Review order"

    assert_text "Check this is right"
    assert_empty contrast_failures("#modal_overlay"),
                 "the review step is a second screen inside the same modal and is easy to miss"
  end

  test "the import dialog clears AA" do
    sign_in(create(:admin))
    visit admin_students_path
    find("button", text: "Import students", match: :first).click

    assert_text "Import students from CSV"
    assert_empty contrast_failures("#import-modal")
  end

  test "both modals share one shell" do
    open_buy_modal
    trading = shell_of("#modal_overlay", "[role='dialog']")

    sign_in(create(:admin))
    visit admin_students_path
    find("button", text: "Import students", match: :first).click
    assert_text "Import students from CSV"
    import = shell_of("#import-modal [aria-hidden='true']", "[data-dialog-target='panel']")

    assert_not_nil trading
    assert_not_nil import

    %w[scrim panelRadius titleTag titleSize titleWeight closeRadius].each do |property|
      assert_equal trading[property], import[property],
                   "the two modals differ on #{property}; they are one shell in one product"
    end

    assert_equal PANEL_RADIUS, trading["panelRadius"], "a modal panel is rounded-2xl"
    assert_equal CONTROL_RADIUS, trading["closeRadius"], "a control is rounded-lg"
    assert_equal "H2", trading["titleTag"]
    [trading, import].each do |modal|
      assert_operator modal["closeTarget"], :>=, 44,
                      "an icon-only close control is a bare tap target, so it keeps 44px"
    end
  end
end
