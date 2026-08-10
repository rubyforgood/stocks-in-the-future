# frozen_string_literal: true

require "application_system_test_case"

# 24px between the page header and whatever follows it, on every page.
#
# design.md states it three times - "the header block is `mb-6` and nothing else", "gap under the page
# header: `mb-6` = 24px", "sections and cards separate by 24px" - and records two ways it has drifted
# before: a `pb-5` left behind when the rule under the title was removed (44px), and a 40px action beside a
# 32px h1 in an `items-start` row (32px). Both were reported as "the spacing looks wrong" and neither was
# visible in the class list.
#
# Swept after a third shape: a form card carrying `mt-4` and a section wrapper carrying `mt-6`, both of
# which measured *nothing*, because adjacent vertical margins collapse to the larger and the header's own
# `mb-6` is bigger. An inert margin is not harmless - the `mt-4` became a live 16px gap the moment an error
# summary appeared between the two, giving that one state a rhythm the rest of the app does not use. So this
# asserts the **rendered gap**: a declaration that does nothing and a declaration that does the right thing
# are indistinguishable in the markup.
#
# It also fails when a page wraps its header block in a spare div, which is how two index pages escaped
# every measurement of this seam until now - the gap only exists between siblings. `display: contents` does
# not rescue that, because `nextElementSibling` walks the DOM rather than the layout tree.
class PageRhythmTest < ApplicationSystemTestCase
  GAP = <<~JS
    (function () {
      // The first element at or under `el` that generates a box. Two things return no rects: display:none,
      // where the children have no boxes either and this correctly gives up, and display:contents, where the
      // element is skipped and its children are laid out in its place. The forms are `form_with class:
      // "contents"`, so without this the content of every form page looks absent.
      function firstBox(el) {
        if (el.getClientRects().length > 0) {
          return el.getBoundingClientRect().height > 0 ? el : null;
        }
        for (const child of el.children) {
          const found = firstBox(child);
          if (found) return found;
        }
        return null;
      }

      const main = document.querySelector("main");
      const h1 = main.querySelector("h1");
      if (!h1) return { skip: "no h1 in main" };

      // A clipped 1px h1 is the admin layout's fallback heading, which it renders only when the page did
      // not declare :own_heading - i.e. when the page has no `_page_header`. Measuring from it gives a
      // meaningless number, so name the actual problem.
      if (h1.getBoundingClientRect().width <= 1) {
        return { skip: "no visible page header - the only h1 is the admin layout's sr-only fallback, " +
                       "so this page never adopted components/ui/_page_header" };
      }

      // Walk out from the h1 to the element carrying the header block's bottom margin.
      let header = h1;
      while (header.parentElement && header.parentElement !== main &&
             parseFloat(getComputedStyle(header).marginBottom) === 0) {
        header = header.parentElement;
      }

      let next = header.nextElementSibling;
      let box = null;
      while (next && !(box = firstBox(next))) next = next.nextElementSibling;
      if (!box) return { skip: "the header block has no rendered sibling - is it wrapped in a spare div?" };

      return {
        gap: Math.round(box.getBoundingClientRect().top - header.getBoundingClientRect().bottom),
        header: header.tagName.toLowerCase() + "." + (header.className || ""),
        next: box.tagName.toLowerCase() + "." + (box.className || "")
      };
    })()
  JS

  def assert_page_rhythm(label, path)
    visit path
    assert_selector "main h1", visible: :all, wait: 5
    result = page.evaluate_script(GAP)

    assert_nil result["skip"], "#{label} (#{path}): #{result['skip']}"
    assert_equal 24, result["gap"],
                 "#{label} (#{path}): #{result['gap']}px under the page header, not 24px. " \
                 "Header block is #{result['header']}, next is #{result['next']}."
  end

  test "every student page keeps the 24px rhythm under the page header" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:, name: "Ada Lovelace")
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(
      :stock,
      ticker: "KO",
      company_name: "Coca-Cola",
      price_cents: 6_241,
      yesterday_price_cents: 6_100,
      last_trading_day: Date.current - 1
    )
    sign_in student

    { "home" => root_path,
      "trading floor" => stocks_path,
      "stock" => stock_path(stock),
      "transactions" => orders_path,
      "profile" => edit_profile_path,
      "portfolio" => user_portfolio_path(student, student.portfolio) }
      .each { |label, path| assert_page_rhythm(label, path) }
  end

  test "every teacher page keeps the 24px rhythm under the page header" do
    classroom = create(:classroom, :with_trading, grades: [create(:grade, level: 5, name: "5th Grade")])
    student = create(:student, :with_portfolio, classroom:, name: "Ada Lovelace")
    teacher = create(:teacher, name: "Terry Teacher")
    create(:teacher_classroom, teacher:, classroom:)
    book = classroom.grade_books.first
    create(:grade_entry, grade_book: book, user: student)
    sign_in teacher

    { "home" => root_path,
      "classrooms" => classrooms_path,
      "classroom" => classroom_path(classroom),
      "classroom edit" => edit_classroom_path(classroom),
      "grade book" => classroom_grade_book_path(classroom, book),
      "new student" => new_classroom_student_path(classroom),
      "edit student" => edit_classroom_student_path(classroom, student) }
      .each { |label, path| assert_page_rhythm(label, path) }
  end

  test "every admin page keeps the 24px rhythm under the page header" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    stock = create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241)
    announcement = Announcement.create!(title: "Notice", content: "Body text.")
    transaction = student.portfolio.portfolio_transactions.first
    sign_in create(:admin)

    { "dashboard" => admin_root_path,
      "users" => admin_users_path,
      "user edit" => edit_admin_user_path(student),
      "classrooms" => admin_classrooms_path,
      "classroom" => admin_classroom_path(classroom),
      "new classroom" => new_admin_classroom_path,
      "students" => admin_students_path,
      "student" => admin_student_path(student),
      "student edit" => edit_admin_student_path(student),
      "teachers" => admin_teachers_path,
      "teacher" => admin_teacher_path(teacher),
      "schools" => admin_schools_path,
      "new school" => new_admin_school_path,
      "school years" => admin_school_years_path,
      "stocks" => admin_stocks_path,
      "stock edit" => edit_admin_stock_path(stock),
      "announcements" => admin_announcements_path,
      "announcement edit" => edit_admin_announcement_path(announcement),
      "transactions" => admin_portfolio_transactions_path,
      "new transaction" => new_admin_portfolio_transaction_path,
      "transaction edit" => edit_admin_portfolio_transaction_path(transaction),
      "new stock" => new_admin_stock_path,
      "new announcement" => new_admin_announcement_path,
      "new teacher" => new_admin_teacher_path,
      "new user" => new_admin_user_path }
      .each { |label, path| assert_page_rhythm(label, path) }
  end
end
