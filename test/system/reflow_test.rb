# frozen_string_literal: true

require "application_system_test_case"

# Walks the main pages at 320px, and again at 320px with text at 200%.
#
# **Why this exists.** Every responsive failure found by hand on this branch would have been caught
# here, and each was found only because somebody happened to look:
#
#   - the staging ribbon passed a 375/1366 review and, at 200% text, rendered its first lines *above*
#     the top of the viewport - `position: fixed`, so unreachable - while covering the header
#   - the trading floor's Buy and Sell buttons sat past the right edge of a scroll container at 375px,
#     while `assert_selector` found them and `click_on` clicked them
#   - `classrooms#show` had a `flex gap-8` that never stacked, so `<main>` itself scrolled sideways
#   - a `.hidden` order-modal button rendered anyway, because an unlayered rule outranked the utility
#
# A checklist does not catch those. design.md's rule is that class names describe intent and only the
# rendered box describes the result, so every assertion here is a measurement.
#
# **320px** is WCAG 1.4.10 (Reflow, AA). **200% text** is 1.4.4 (Resize text, AA), and it is the one
# that gets missed, because a page that is fine at 320px can break entirely at 320px *and* 200%.
class ReflowTest < ApplicationSystemTestCase
  # Returns every violation on the page, so a failure names all of them at once rather than one per
  # run. Each entry is a short string, because a failure message is read by a person.
  AUDIT = <<~JS
    (function () {
      const problems = [];
      const doc = document.documentElement;

      // 1. The page itself must not scroll sideways. A page-level scroll also defeats a pinned table
      //    cell, because the cell pins to a container that is itself being pushed.
      if (doc.scrollWidth > doc.clientWidth + 1) {
        problems.push("page scrolls sideways: scrollWidth " + doc.scrollWidth +
                      " > clientWidth " + doc.clientWidth);
      }

      const visible = (el) => {
        const s = getComputedStyle(el);
        if (s.display === "none" || s.visibility === "hidden" || s.opacity === "0") return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
      };

      // `sr-only` is deliberately clipped out of view, and a closed drawer is translated off to the
      // left on purpose. Neither is a defect.
      const deliberate = (el) => el.closest(".sr-only, [data-drawer-target='panel']") !== null;

      // 2. Nothing rendered above the top of the viewport at scroll position 0. Content up there is
      //    unreachable when its element is fixed, and merely wrong when it is not.
      for (const el of doc.querySelectorAll("*")) {
        if (el.children.length > 0) continue;
        if (!el.innerText || !el.innerText.trim()) continue;
        if (!visible(el) || deliberate(el)) continue;
        const r = el.getBoundingClientRect();
        if (r.top < -1) {
          problems.push('"' + el.innerText.trim().slice(0, 40) + '" renders at y=' +
                        Math.round(r.top) + ", above the viewport");
        }
      }

      // 3. A `.hidden` element whose computed display is not none. An unlayered CSS rule beats every
      //    layered one whatever the specificity, and that is how four order-modal buttons showed at
      //    once while the markup said hidden.
      for (const el of doc.querySelectorAll(".hidden")) {
        if (getComputedStyle(el).display !== "none") {
          problems.push(".hidden element still displayed: " + el.tagName.toLowerCase() + "." +
                        [...el.classList].slice(0, 3).join("."));
        }
      }

      return problems;
    })()
  JS

  # Each page is measured at 320px and then again with text doubled, and every violation from every
  # page is collected before failing - one run should tell you everything that is wrong, not the first
  # thing.
  def assert_reflows(paths)
    failures = []

    in_reflow_viewport do
      paths.each do |label, path|
        visit path
        Array(page.evaluate_script(AUDIT)).each { |problem| failures << "#{label} @320px: #{problem}" }

        apply_200_percent_text
        Array(page.evaluate_script(AUDIT)).each do |problem|
          failures << "#{label} @320px, 200% text: #{problem}"
        end
      end
    end

    assert_empty failures, "\n#{failures.join("\n")}"
  end

  test "the signed-out pages reflow" do
    assert_reflows(
      "sign in" => new_user_session_path,
      "forgot password" => new_user_password_path
    )
  end

  test "the student pages reflow" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    # **With earnings**, so the breakdown renders its rows rather than its empty state. Without a reason the
    # deposit counts towards nothing, every row reads $0.00, the card shows one sentence instead - and the
    # overflow that a `$1,150.00` beside its label causes at 200% text went unmeasured on this page. A
    # fixture that renders an empty state is not testing the populated one.
    create(
      :portfolio_transaction, :deposit,
      portfolio: student.portfolio, amount_cents: 115_000, reason: :attendance_earnings
    )
    create(
      :portfolio_stock, portfolio: student.portfolio, stock: (stock = create(:stock)), shares: 100,
                        purchase_price: stock.price_cents
    )
    create(:order, :sell, user: student, stock:, shares: 1)
    sign_in student

    assert_reflows(
      "home" => root_path,
      "trading floor" => stocks_path,
      "transactions" => orders_path,
      "portfolio" => user_portfolio_path(student, student.portfolio)
    )
  end

  test "the teacher pages reflow" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    create(:student, :with_portfolio, classroom:)
    sign_in teacher

    assert_reflows(
      "home" => root_path,
      "classrooms" => classrooms_path,
      "classroom" => classroom_path(classroom),
      "trading floor" => stocks_path
    )
  end

  # **The failure a page-level check cannot see.** `.tw-card` is `overflow-hidden`, so an element too wide
  # for its card is *clipped* rather than pushed onto the page: the document never scrolls, the audit above
  # passes, and a figure is cut in half. Measured on the earnings breakdown at 320px and 200% text, a
  # `$1,150.00` sat 57px past its card's edge with the page reporting no overflow at all.
  #
  # Restricted to definition-list rows inside a card. A table cell legitimately extends past the wrapper it
  # is in, because the scroller is the div between them - so including cells here would report every wide
  # table as a defect.
  test "a figure is never clipped by the card it sits in" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.reload
    { attendance_earnings: 50_000, reading_earnings: 50_000,
      math_earnings: 10_000, awards: 5_000 }.each do |reason, cents|
      create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: cents, reason:)
    end
    create(
      :portfolio_transaction,
      portfolio: student.portfolio, transaction_type: :fee, amount_cents: 100, reason: :transaction_fees
    )
    sign_in create(:admin)

    clipped_rows = <<~JS
      (function () {
        const out = [];
        document.querySelectorAll("main .tw-card dl dt, main .tw-card dl dd").forEach(function (el) {
          const card = el.closest(".tw-card");
          const e = el.getBoundingClientRect();
          const c = card.getBoundingClientRect();
          if (e.right > c.right + 1 || e.left < c.left - 1) {
            out.push(JSON.stringify(el.textContent.trim().slice(0, 24)) + " is clipped by its card: " +
                     Math.round(Math.max(e.right - c.right, c.left - e.left)) + "px past the edge");
          }
        });
        return out;
      })()
    JS

    in_reflow_viewport do
      [admin_student_path(student), user_portfolio_path(student, student.portfolio)].each do |path|
        visit path
        apply_200_percent_text

        assert_empty Array(page.evaluate_script(clipped_rows)), "#{path} at 320px and 200% text"
      end
    end
  end

  test "the admin pages reflow" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.reload
    # A record page with something in every section: two forms, an earnings breakdown, a transaction and an
    # attendance row. The index was walked here and the record page was not, which is the wrong way round -
    # a page of fields and figures reflows less easily than a table that collapses.
    create(
      :portfolio_transaction, :deposit,
      portfolio: student.portfolio, amount_cents: 100_000, reason: :attendance_earnings
    )
    quarter = student.classroom.school_year.quarters.find_by!(number: 1)
    grade_book = student.classroom.grade_books.find_by!(quarter:)
    create(:grade_entry, grade_book:, user: student, attendance_days: 42)
    create(:stock)
    sign_in create(:admin)

    assert_reflows(
      "dashboard" => admin_root_path,
      "classrooms" => admin_classrooms_path,
      "students" => admin_students_path,
      "student" => admin_student_path(student),
      "teachers" => admin_teachers_path,
      "stocks" => admin_stocks_path,
      "school years" => admin_school_years_path,
      "announcements" => admin_announcements_path
    )
  end
end
