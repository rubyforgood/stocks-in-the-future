# frozen_string_literal: true

require "application_system_test_case"

# design.md, Buttons: "One primary CTA per page." A view gets exactly one filled :primary - its
# main action - and every other action is lower emphasis. A dialog keeps its own primary confirm,
# which is visible only while the modal is open, so it does not count against the page.
#
# Two pages broke it, both in the shapes the rule names:
#
#   - admin/students#edit stacked "Update student" with a second card's "Add transaction". That is
#     the sub-form submit case: an inline submit inside a management card is :secondary, never
#     :primary.
#   - portfolios#show rendered a filled "Trade" in every holdings row - a per-row filled CTA, the
#     thing the row-action rule exists to prevent, and a table the earlier ghost sweep missed -
#     plus "Go to the trading floor" in its empty state alongside the earnings card's "Invest now",
#     two primaries pointing at the same path.
class OnePrimaryTest < ApplicationSystemTestCase
  # Excludes anything inside a dialog or the modal turbo-frame.
  PAGE_PRIMARIES = <<~JS
    (function () {
      const out = [];
      document.querySelectorAll(".tw-btn-primary").forEach(function (el) {
        if (el.getClientRects().length === 0) return;
        if (el.closest("dialog, [role=dialog], turbo-frame#modal_frame")) return;
        out.push((el.value || el.textContent || "").replace(/\\s+/g, " ").trim().slice(0, 30));
      });
      return out;
    })()
  JS

  # The page header's own action row: how many, and whether any of them is already offered elsewhere on
  # the same page.
  #
  # `page_header` puts actions in the block that holds the h1, so this reads that block rather than the
  # whole page - a row action or a card's control is governed by other rules.
  HEADER_ACTIONS = <<~JS
    (function () {
      const h1 = document.querySelector("main h1");
      if (!h1) return null;
      const block = h1.closest("div.mb-6");
      if (!block) return null;

      // A destructive link and a form's Cancel share an href and differ only in verb, so the key carries
      // the method: DELETE /admin/students/1 is not the same control as GET /admin/students/1. Without
      // this, five record pages report a duplicate that is not one.
      const key = function (el) {
        const h = el.getAttribute("href");
        return h === null || h.startsWith("#") ? null : (el.dataset.turboMethod || "get") + " " + h;
      };

      const labels = Array.from(block.querySelectorAll("a, button")).filter(function (el) {
        return el.getClientRects().length > 0 && (el.innerText || "").trim().length > 0;
      }).map(function (el) { return (el.innerText || "").trim().replace(/\s+/g, " "); });

      const duplicated = [];
      Array.from(block.querySelectorAll("a[href]")).forEach(function (a) {
        const k = key(a);
        if (!k) return;
        const elsewhere = Array.from(document.querySelectorAll("main a[href]")).filter(function (b) {
          return b !== a && !block.contains(b) && key(b) === k;
        });
        if (elsewhere.length) {
          duplicated.push((a.innerText || "").trim() + " -> " + k + ", also offered as " +
                          elsewhere.map(function (b) {
                            return "'" + (b.innerText || "").trim().slice(0, 30) + "'";
                          }).join(", "));
        }
      });

      return { labels: labels, duplicated: duplicated };
    })()
  JS

  # Three is the ceiling the field converges on - Atlassian, Salesforce and Material 3 all cap a header at
  # three actions and send the rest to an overflow, and Polaris and Stripe are stricter still. This app
  # sits at two everywhere, so the assertion is headroom rather than a description: a fourth action is a
  # decision, not a drift.
  MAX_HEADER_ACTIONS = 3

  def assert_header_actions(label, path)
    visit path
    header = page.evaluate_script(HEADER_ACTIONS)
    return if header.nil?

    labels = header["labels"]

    assert_operator labels.size, :<=, MAX_HEADER_ACTIONS,
                    "#{label} has #{labels.size} page-header actions: #{labels.join(' | ')}. " \
                    "Three is the ceiling; a supporting step belongs with the task it supports."

    # **The defect this was written for.** `admin/students` carried a "Download template" button pointing
    # where the "Download a template" link *inside the import dialog* already pointed - one destination,
    # two controls, and the header's copy was the worse of the two because the dialog's sits beside the
    # list of required columns. Measured at 375px, that third button wrapped the row and pushed the
    # **primary** below both secondaries: "New student" at top=172 under two buttons at top=124, header
    # block 132px against 40px at 1366px.
    assert_empty header["duplicated"],
                 "#{label}: #{header['duplicated'].join(' | ')}. One destination, one control."
  end

  def assert_one_primary(label, path)
    visit path
    primaries = page.evaluate_script(PAGE_PRIMARIES)

    assert_operator primaries.size, :<=, 1,
                    "#{label} has #{primaries.size} filled primary buttons: " \
                    "#{primaries.join(' | ')}. One per page - the page's main action; everything " \
                    "else is secondary or ghost."
  end

  test "student pages have at most one primary" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    sign_in(student)

    assert_one_primary("home", root_path)
    assert_one_primary("stocks", stocks_path)
    assert_one_primary("stock show", stock_path(stock))
    assert_one_primary("orders", orders_path)
    assert_one_primary("portfolio", user_portfolio_path(student, student.portfolio))
  end

  test "a holdings row action is a ghost, not a filled CTA" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    create(:portfolio_stock, portfolio: student.portfolio, stock:, shares: 2)
    sign_in(student)

    visit user_portfolio_path(student, student.portfolio)

    trade = find("tbody a", text: "Trade")

    assert_equal 1, trade.all("svg", visible: :all).size, "the row action needs its leading icon"
    assert_no_selector "tbody a.tw-btn-primary"
  end

  test "the trading floor card does not link to the page it is on" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    sign_in(student)

    visit stocks_path

    # A primary CTA whose href is the current page does nothing.
    assert_no_link "Invest now"
  end

  test "admin pages have at most one primary" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    sign_in(create(:admin))

    {
      "dashboard" => admin_root_path,
      "users" => admin_users_path,
      "student edit" => edit_admin_student_path(student),
      "student show" => admin_student_path(student),
      "classroom show" => admin_classroom_path(classroom),
      "school_year show" => admin_school_year_path(school_year)
    }.each { |label, path| assert_one_primary(label, path) }
  end

  test "no page header carries more than three actions, or one destination twice" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    announcement = Announcement.create!(title: "Half day", content: "Noon.")
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(create(:admin))

    # `admin/students` was not in this file's walk, which is how a third header action arrived unnoticed.
    { "students" => admin_students_path,
      "student show" => admin_student_path(student),
      "student edit" => edit_admin_student_path(student),
      "users" => admin_users_path,
      "user show" => admin_user_path(student),
      "classrooms" => admin_classrooms_path,
      "classroom show" => admin_classroom_path(classroom),
      "teachers" => admin_teachers_path,
      "teacher show" => admin_teacher_path(teacher),
      "stocks" => admin_stocks_path,
      "stock show" => admin_stock_path(stock),
      "announcements" => admin_announcements_path,
      "announcement show" => admin_announcement_path(announcement),
      "transactions" => admin_portfolio_transactions_path,
      "schools" => admin_schools_path,
      "school show" => admin_school_path(school),
      "school years" => admin_school_years_path,
      "dashboard" => admin_root_path }.each { |label, path| assert_header_actions(label, path) }

    sign_in(student)
    { "home" => root_path, "stocks" => stocks_path, "stock show" => stock_path(stock),
      "orders" => orders_path,
      "portfolio" => user_portfolio_path(student, student.portfolio) }
      .each { |label, path| assert_header_actions(label, path) }

    sign_in(teacher)
    { "classrooms" => classrooms_path, "classroom show" => classroom_path(classroom) }
      .each { |label, path| assert_header_actions(label, path) }
  end
end
