# frozen_string_literal: true

require "application_system_test_case"

# The card that replaced the header's scrolling stock ticker.
#
# The ticker failed WCAG 2.2.2 at Level A - content moving automatically for more than five seconds with no
# way to pause, stop or hide it - its two colours measured 2.74:1 and 3.78:1 against AA's 4.5:1, and it
# showed a symbol and a percentage with no price, no company name and no link. See migration.md.
class TodaysMoversTest < ApplicationSystemTestCase
  def a_student_on_the_home_page
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    sign_in student
    student
  end

  test "the scrolling ticker is gone, and nothing on the page animates" do
    a_student_on_the_home_page

    visit root_path

    assert_no_selector ".ticker-content", visible: :all
    assert_no_selector ".animate-scroll", visible: :all

    animating = page.evaluate_script(<<~JS)
      (function () {
        return Array.from(document.querySelectorAll("*"))
          .filter(function (el) { return getComputedStyle(el).animationName !== "none"; })
          .map(function (el) { return el.tagName.toLowerCase() + "." + el.className.toString().slice(0, 30); });
      })()
    JS

    assert_empty animating, "still animating: #{animating.join(', ')}"
  end

  test "the card lists movers with company name, price and change" do
    a_student_on_the_home_page
    create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241, yesterday_price_cents: 6_100)
    create(
      :stock,
      ticker: "F", company_name: "Ford Motor Company", price_cents: 1_108, yesterday_price_cents: 1_300
    )

    visit root_path

    within "section", text: "Today's movers" do
      assert_text "Coca-Cola"
      assert_text "KO"
      assert_text "$62.41"
      assert_text "Ford Motor Company"
      assert_text "-14.77%"
      # Each row is a link to the company, which the ticker never was.
      assert_link href: stock_path(Stock.find_by(ticker: "F"))
    end
  end

  # The help text is the reason this card is allowed to exist. A "biggest movers" list put in front of
  # eleven-year-olds teaches buying what went up, which is the opposite of what this app is for. All three
  # things it has to say are in the subtitle: what the list is, that moving most is not a recommendation,
  # and what to do instead.
  test "the card explains what a move means and what it does not mean" do
    a_student_on_the_home_page
    create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241, yesterday_price_cents: 6_100)

    visit root_path

    within "section", text: "Today's movers" do
      assert_text "The biggest price changes since yesterday"
      assert_text "does not make a company a better buy"
      assert_text "open one to see what it does"
    end
  end

  # Up, down, flat - and never colour alone: the sign is in the text and the arrow is in the markup.
  test "direction is carried by the sign and an arrow, not only by colour" do
    a_student_on_the_home_page
    create(:stock, ticker: "UP", company_name: "Riser", price_cents: 11_000, yesterday_price_cents: 10_000)
    create(:stock, ticker: "DOWN", company_name: "Faller", price_cents: 9_000, yesterday_price_cents: 10_000)

    visit root_path

    rows = page.evaluate_script(<<~JS)
      (function () {
        const heading = Array.from(document.querySelectorAll("h2, h3, p"))
          .find(function (e) { return e.textContent.trim() === "Today's movers"; });
        return Array.from(heading.closest(".tw-card").querySelectorAll("li a")).map(function (a) {
          const nums = a.querySelectorAll("span.tabular-nums");
          return { name: a.querySelector(".font-medium").textContent.trim(),
                   change: nums[nums.length - 1].textContent.trim(),
                   arrows: a.querySelectorAll("svg").length };
        });
      })()
    JS

    riser = rows.find { it["name"] == "Riser" }
    faller = rows.find { it["name"] == "Faller" }

    assert_equal "+10.00%", riser["change"]
    assert_equal "-10.00%", faller["change"]
    assert_equal 1, riser["arrows"]
    assert_equal 1, faller["arrows"]
  end

  # An unchanged stock is not a mover, so it is not listed at all - the ticker called every one of them a
  # gain, because its test was `>= 0` and nothing had a yesterday price.
  test "a card with no movement says so instead of showing zeroes" do
    a_student_on_the_home_page
    create(
      :stock,
      ticker: "FLAT", company_name: "Steady", price_cents: 10_000, yesterday_price_cents: 10_000
    )

    visit root_path

    within "section", text: "Today's movers" do
      assert_text "No price movement recorded yet"
      assert_no_text "0.00%"
      assert_no_text "Steady"
    end
  end

  # The balance is what a student comes to this page for, so the card goes below it. design.md's rule,
  # measured once at a cost of 421px on the roster.
  test "the card sits below the balance, not above it" do
    a_student_on_the_home_page
    create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241, yesterday_price_cents: 6_100)

    visit root_path

    order = page.evaluate_script(<<~JS)
      (function () {
        const tops = {};
        document.querySelectorAll("main h2, main h3, main p").forEach(function (el) {
          const t = el.textContent.trim();
          if (t === "Earnings to invest" || t === "Today's movers") {
            tops[t] = Math.round(el.getBoundingClientRect().top + window.scrollY);
          }
        });
        return tops;
      })()
    JS

    assert order["Earnings to invest"], "no balance card on the student home page"
    assert_operator order["Earnings to invest"], :<, order["Today's movers"],
                    "the movers card is above the balance"
  end

  # The help text is the card's subtitle, not a band under the rows. It was a capped paragraph leaving
  # 407px of the card empty, then two columns that used the width but changed shape between viewports -
  # one column below lg, two above, under rows that never change shape at all. Reported as jarring.
  #
  # A subtitle has neither problem: it fills the header's width, and at 122 characters it is one line at
  # both widths this app is used at. Asserted as *shape*, not as pixels: no band inside the card, and the
  # subtitle reaching the header's content width.
  test "the help text is the subtitle, with no band under the rows" do
    a_student_on_the_home_page
    create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241, yesterday_price_cents: 6_100)

    [nil, :phone].each do |viewport|
      run = lambda do
        visit root_path

        shape = page.evaluate_script(<<~JS)
          (function () {
            const heading = Array.from(document.querySelectorAll("h2, h3, p"))
              .find(function (e) { return e.textContent.trim() === "Today's movers"; });
            const card = heading.closest(".tw-card");
            const header = heading.closest("header");
            const sub = header.querySelector("p");
            const cs = getComputedStyle(header);
            const inner = header.getBoundingClientRect().width -
                          parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
            return { bands: card.querySelectorAll(".border-t").length,
                     columns: card.querySelectorAll("div.grid p").length,
                     subtitle: Math.round(sub.getBoundingClientRect().width),
                     headerInner: Math.round(inner) };
          })()
        JS

        assert_equal 0, shape["bands"], "there is still a band under the rows"
        assert_equal 0, shape["columns"], "the help text is still in columns"
        assert_in_delta shape["headerInner"], shape["subtitle"], 2,
                        "the subtitle is #{shape['subtitle']}px inside #{shape['headerInner']}px of " \
                        "header, so it leaves the card unfinished on the right"
      end

      viewport == :phone ? in_phone_viewport { run.call } : run.call
    end
  end
end
