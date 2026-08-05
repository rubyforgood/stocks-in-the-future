# frozen_string_literal: true

require "application_system_test_case"

# design.md, Copy: a button label is a verb-first phrase of at most three words, and one
# destination gets one label.
#
# Both rules were broken in ways a reader would not notice from any single page. stocks_path was
# reached by six labels - "Go to the trading floor", "Invest now" (twice), "See the companies",
# "Trade", "Trade stock" - and "Back to stocks" named it a fifth thing while its own h1 and its
# nav item both say "Trading floor".
#
# The self-link assertion is the second half. design.md records an "Invest now" on the trading
# floor that linked to the trading floor, which is why the guard exists; the sweep that added this
# test also turned up a "View details" button pointing at stocks#show from a partial only
# stocks#show renders - though that one was inside an unreachable branch, so it never rendered at
# all and this assertion would not have caught it. Dead markup needs a different check.
class ButtonCopyTest < ApplicationSystemTestCase
  MAX_WORDS = 3

  # A back link names where it goes, which is worth more than the word count: "Back to school
  # years" beats "Back". Everything else earns its length or gets shorter.
  EXEMPT = [/\ABack to /, /\AAdd the first /].freeze

  BUTTONS = <<~JS
    (function () {
      const sel = ".tw-btn-primary, .tw-btn-secondary, .tw-btn-danger-outline, [class*='min-h-8']";
      const out = [];
      document.querySelectorAll(sel).forEach(function (el) {
        if (el.getClientRects().length === 0) return;
        // The sr-only half of a split label is part of the accessible name, not the visible copy.
        const clone = el.cloneNode(true);
        clone.querySelectorAll(".sr-only").forEach(function (s) { s.remove(); });
        const label = (el.value || clone.textContent || "").replace(/\\s+/g, " ").trim();
        if (!label) return;
        out.push({ label: label, href: el.getAttribute("href") });
      });
      return out;
    })()
  JS

  def buttons_on(path)
    visit path
    page.evaluate_script(BUTTONS)
  end

  def student_pages
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    sign_in(student)

    { "home" => root_path,
      "trading floor" => stocks_path,
      "stock" => stock_path(stock),
      "orders" => orders_path,
      "portfolio" => user_portfolio_path(student, student.portfolio) }
  end

  test "no button label runs longer than three words" do
    student_pages.each do |label, path|
      buttons_on(path).each do |button|
        copy = button["label"]
        next if EXEMPT.any? { |pattern| copy.match?(pattern) }

        assert_operator copy.split.size, :<=, MAX_WORDS,
                        "#{label}: \"#{copy}\" is #{copy.split.size} words. A button label is a " \
                        "verb-first phrase of at most #{MAX_WORDS} words."
      end
    end
  end

  test "no button navigates to the page it is on" do
    student_pages.each do |label, path|
      buttons_on(path).each do |button|
        href = button["href"]
        next if href.blank? || href.start_with?("#")

        assert_not_equal URI.parse(path).path, URI.parse(href).path,
                         "#{label}: \"#{button['label']}\" links to the page it is rendered on"
      end
    end
  end
end
