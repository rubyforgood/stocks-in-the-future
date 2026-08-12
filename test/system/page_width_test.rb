# frozen_string_literal: true

require "application_system_test_case"

# No page may push <main> sideways at 375px.
#
# A horizontal scroll on the page itself is different from a table that scrolls inside its own
# container: it moves everything, including controls pinned to a container that is itself being
# pushed right, and it is invisible at desktop widths. Three separate causes were found by
# measuring every page in the app at 375px:
#
#   - classroom#show laid the roster beside the grade book list with a bare `flex gap-8`, so 812px
#     of content sat in a 328px viewport.
#   - the admin breadcrumb trail was an unwrappable `inline-flex`, and a school year's crumb reads
#     "School name (2024-2025)" - 130px past the viewport, on six pages.
#   - the order form's Back and submit buttons carry `hidden` and rendered anyway, because
#     buttons.css was unlayered and `.tw-btn-buy { display: inline-flex }` beat `.hidden`.
#
# None of them failed a test, and none is visible at 1366px.
class PageWidthTest < ApplicationSystemTestCase
  def overflow_of_main
    page.evaluate_script(<<~JS)
      (function () {
        const m = document.querySelector("main");
        return m ? m.scrollWidth - m.clientWidth : 0;
      })()
    JS
  end

  # Names the element responsible, so a failure says what to fix rather than only that it broke.
  def blame
    page.evaluate_script(<<~JS)
      (function () {
        const m = document.querySelector("main");
        if (!m) return "";
        const edge = m.getBoundingClientRect().right;
        const out = [];
        m.querySelectorAll("*").forEach(function (el) {
          const b = el.getBoundingClientRect();
          if (b.width === 0 || b.right <= edge + 1) return;
          let p = el.parentElement;
          while (p && p !== m) {
            const ox = getComputedStyle(p).overflowX;
            if (ox === "auto" || ox === "scroll") return;
            p = p.parentElement;
          }
          if (Array.from(el.children).some(function (c) {
            const cb = c.getBoundingClientRect();
            return cb.width > 0 && cb.right > edge + 1;
          })) return;
          out.push(el.tagName.toLowerCase() + "." + String(el.className).slice(0, 40));
        });
        return out.slice(0, 3).join(", ");
      })()
    JS
  end

  def assert_fits(label, path)
    visit path
    over = overflow_of_main

    assert_operator over, :<=, 1,
                    "#{label} pushes <main> #{over}px sideways at 375px. Blame: #{blame}"
  end

  test "signed out pages fit 375px" do
    in_phone_viewport do
      assert_fits("sign in", new_user_session_path)
      assert_fits("sign up", new_user_registration_path)
      assert_fits("forgot password", new_user_password_path)
    end
  end

  test "student pages fit 375px" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    order = create(:order, user: student, stock:, shares: 1, status: :pending, action: :buy)
    sign_in(student)

    in_phone_viewport do
      assert_fits("home", root_path)
      assert_fits("stocks", stocks_path)
      assert_fits("stock show", stock_path(stock))
      assert_fits("orders", orders_path)
      assert_fits("order edit", edit_order_path(order))
      assert_fits("new order", new_order_path(stock_id: stock.id, transaction_type: :buy))
      assert_fits("portfolio", user_portfolio_path(student, student.portfolio))
    end
  end

  test "teacher pages fit 375px" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    grade_book = classroom.grade_books.first || create(:grade_book, classroom:)
    sign_in(teacher)

    in_phone_viewport do
      assert_fits("classrooms", classrooms_path)
      assert_fits("classroom show", classroom_path(classroom))
      assert_fits("classroom edit", edit_classroom_path(classroom))
      assert_fits("grade book", classroom_grade_book_path(classroom, grade_book))
      assert_fits("new student", new_classroom_student_path(classroom))
      assert_fits("edit student", edit_classroom_student_path(classroom, student))
    end
  end

  # The breadcrumb trail is the reason show and edit pages are covered here and not only the
  # indexes: it is longest on exactly those, and it is what overflowed.
  test "admin pages fit 375px" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    txn = student.portfolio.portfolio_transactions.first
    announcement = Announcement.create!(title: "Notice", content: "Body text for the announcement.")
    sign_in(create(:admin))

    pages = {
      "dashboard" => admin_root_path,
      "users" => admin_users_path,
      "user edit" => edit_admin_user_path(student),
      "classrooms" => admin_classrooms_path,
      "classroom show" => admin_classroom_path(classroom),
      "classroom edit" => edit_admin_classroom_path(classroom),
      "students" => admin_students_path,
      "student show" => admin_student_path(student),
      "teachers" => admin_teachers_path,
      "teacher show" => admin_teacher_path(teacher),
      "teacher edit" => edit_admin_teacher_path(teacher),
      "schools" => admin_schools_path,
      "school edit" => edit_admin_school_path(school),
      "school_years" => admin_school_years_path,
      "school_year show" => admin_school_year_path(school_year),
      "school_year edit" => edit_admin_school_year_path(school_year),
      "stocks" => admin_stocks_path,
      "stock edit" => edit_admin_stock_path(stock),
      "announcements" => admin_announcements_path,
      "announcement new" => new_admin_announcement_path,
      "announcement edit" => edit_admin_announcement_path(announcement),
      "transactions" => admin_portfolio_transactions_path,
      "transaction edit" => edit_admin_portfolio_transaction_path(txn)
    }

    in_phone_viewport { pages.each { |label, path| assert_fits(label, path) } }
  end

  # The cause behind one of the overflows, asserted directly because it is not really about width:
  # a component class must lose to a utility, or `hidden` silently stops working.
  # **One measure for every page that holds a form**, and it is 768px - `max-w-3xl`, the same column the nine
  # admin record pages use, because a create page must not be a different width from the record it creates.
  #
  # Reported as "cards for new students and new teachers are different widths". Measured at 1366px on the
  # input rather than the wrapper, there were **five** measures across the app: 384px on the auth pages,
  # 630px on the app-side forms, 726px on the record pages and three create pages, 854px on new announcement,
  # and 1020px on four create pages that had no column of their own and inherited the layout's `max-w-7xl`.
  test "every page that holds a form uses one column" do
    school = create(:school)
    year = create(:year)
    school_year = create(:school_year, school:, year:)
    classroom = create(:classroom, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    teacher = create(:teacher)
    stock = create(:stock)
    announcement = Announcement.create!(title: "Notice", content: "Body")
    sign_in(create(:admin))

    column = <<~JS
      (function () {
        const col = document.querySelector("main .max-w-3xl");
        return col ? Math.round(col.getBoundingClientRect().width) : 0;
      })()
    JS

    { "schools#new" => new_admin_school_path,
      "schools#show" => admin_school_path(school),
      "school_years#new" => new_admin_school_year_path,
      "school_years#show" => admin_school_year_path(school_year),
      "classrooms#new" => new_admin_classroom_path,
      "classrooms#show" => admin_classroom_path(classroom),
      "students#new" => new_admin_student_path,
      "students#show" => admin_student_path(student),
      "teachers#new" => new_admin_teacher_path,
      "teachers#show" => admin_teacher_path(teacher),
      "users#new" => new_admin_user_path,
      "users#show" => admin_user_path(student),
      "stocks#new" => new_admin_stock_path,
      "stocks#show" => admin_stock_path(stock),
      "announcements#new" => new_admin_announcement_path,
      "announcements#show" => admin_announcement_path(announcement),
      "transactions#new" => new_admin_portfolio_transaction_path }.each do |label, path|
      visit path

      assert_equal 768, page.evaluate_script(column),
                   "#{label}: the form column is not the 768px every other one is"
    end
  end

  # **And a field is as wide as its content, not as wide as the column.** Reported in the same breath - "some
  # of these look very wide" - and it is the half a column cannot fix: a 726px box for a two-letter ticker.
  # GOV.UK states the rule and ships width modifiers, Tailwind UI spans 2 to 6 of 12 columns per field, and
  # Polaris groups short fields rather than stacking full-width ones.
  test "a short field is not as wide as its column" do
    create(:stock, ticker: "AAPL")
    sign_in(create(:admin))

    visit new_admin_stock_path

    widths = page.evaluate_script(<<~JS)
      (function () {
        const out = {};
        document.querySelectorAll("main form label.tw-label-primary").forEach(function (l) {
          const c = document.getElementById(l.getAttribute("for"));
          if (c) out[l.innerText.replace(/\s+/g, " ").trim()] = Math.round(c.getBoundingClientRect().width);
        });
        return out;
      })()
    JS

    assert_equal 128, widths["Ticker symbol*"], "a ticker is four characters and its field is not short"
    assert_equal 128, widths["Number of employees"]
    assert_equal 192, widths["Current price"], "money is not a medium field"
    assert_equal 384, widths["Company name"], "a name is not a long field"
    # And what genuinely needs the width keeps it.
    assert_equal 726, widths["Company website"], "a URL should still fill the column"
  end

  test "a utility overrides a component class" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(:stock, ticker: "AAPL", company_name: "Apple Inc.", price_cents: 15_000)
    sign_in(student)

    # At 375px only the base utilities apply, so a `hidden` element that still renders is a real
    # cascade failure rather than a `hidden lg:block` pair doing its job.
    in_phone_viewport do
      visit new_order_path(stock_id: stock.id, transaction_type: :buy)
      assert_empty hidden_but_still_rendered,
                   "these carry .hidden and still render. A rule outside @layer beats every " \
                   "layered one, so an unlayered component class wins against .hidden no matter " \
                   "the specificity."
    end
  end

  def hidden_but_still_rendered
    page.evaluate_script(<<~JS)
      (function () {
        const out = [];
        document.querySelectorAll(".hidden").forEach(function (el) {
          if (getComputedStyle(el).display !== "none") {
            out.push((el.value || el.textContent || el.tagName).replace(/\s+/g, " ").trim().slice(0, 24));
          }
        });
        return out;
      })()
    JS
  end
end
