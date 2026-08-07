# frozen_string_literal: true

require "application_system_test_case"

# No page renders template syntax as visible text.
#
# This has now happened three times in this codebase, and every time it passed lint and passed the suite,
# because neither reads the page:
#
#   - a `*/` inside a CSS comment ended it early and broke the Tailwind build
#   - a closing ERB delimiter inside an ERB comment leaked a sentence onto a rendered page
#   - and again, in `home/_todays_movers`, where a note *about* that trap contained the delimiter and
#     dumped its own second half above the card
#
# The mechanism is always the same: a comment that contains its own terminator ends at the terminator, and
# everything after it becomes content. A comment is not inert.
#
# Asserted on the rendered text of each page rather than by grepping the templates, because the templates
# are exactly where it looks correct.
class NoLeakedTemplateSyntaxTest < ApplicationSystemTestCase
  # Built from character codes rather than written out, so this file does not contain the sequences it
  # searches for - otherwise a grep of the suite for the bug finds the test looking for it.
  LT = 60.chr   # <
  PCT = 37.chr  # %
  GT = 62.chr   # >
  LBRACE = 123.chr

  DELIMITERS = [LT + PCT, PCT + GT, LT + PCT + 35.chr, LBRACE * 2].freeze

  LEAK = <<~JS
    (function () {
      // innerText, not innerHTML: this is about what a reader sees, and innerText skips display:none.
      const text = document.querySelector("main") ? document.querySelector("main").innerText : "";
      const found = [];
      arguments[0].forEach(function (d) {
        const at = text.indexOf(d);
        if (at >= 0) found.push(d + " near: " + text.slice(Math.max(0, at - 60), at + 60).replace(/\\s+/g, " "));
      });
      return found;
    })
  JS

  def assert_no_leaked_syntax(label, path)
    visit path
    leaks = page.evaluate_script("(#{LEAK})(#{DELIMITERS.to_json})")

    assert_empty leaks, "#{label} renders template syntax as text: #{leaks.join(' | ')}"
  end

  test "no page a student sees leaks template syntax" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)
    stock = create(
      :stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241,
              yesterday_price_cents: 6_100
    )
    create(:order, user: student, stock:, shares: 1, status: :pending, action: :buy)
    Announcement.create!(title: "Half day Friday", content: "School closes at noon.")
    sign_in student

    { "home" => root_path,
      "stocks" => stocks_path,
      "stock" => stock_path(stock),
      "orders" => orders_path,
      "portfolio" => user_portfolio_path(student, student.portfolio) }
      .each { |label, path| assert_no_leaked_syntax(label, path) }
  end

  test "no page a teacher sees leaks template syntax" do
    classroom = create(:classroom, :with_trading)
    2.times { create(:student, :with_portfolio, classroom:) }
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    book = classroom.grade_books.first
    classroom.users.students.each { |s| create(:grade_entry, grade_book: book, user: s) }
    create(
      :stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241,
              yesterday_price_cents: 6_100
    )
    sign_in teacher

    { "home" => root_path,
      "classrooms" => classrooms_path,
      "classroom" => classroom_path(classroom),
      "classroom edit" => edit_classroom_path(classroom),
      "grade book" => classroom_grade_book_path(classroom, book),
      "new student" => new_classroom_student_path(classroom) }
      .each { |label, path| assert_no_leaked_syntax(label, path) }
  end

  test "no admin page leaks template syntax" do
    school_year = create(:school_year, school: create(:school), year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:teacher_classroom, teacher: create(:teacher), classroom:)
    create(
      :stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241,
              yesterday_price_cents: 6_100
    )
    Announcement.create!(title: "Notice", content: "Body text.")
    sign_in create(:admin)

    { "dashboard" => admin_root_path,
      "users" => admin_users_path,
      "classrooms" => admin_classrooms_path,
      "students" => admin_students_path,
      "student" => admin_student_path(student),
      "teachers" => admin_teachers_path,
      "stocks" => admin_stocks_path,
      "announcements" => admin_announcements_path,
      "transactions" => admin_portfolio_transactions_path }
      .each { |label, path| assert_no_leaked_syntax(label, path) }
  end

  test "the signed-out pages do not leak either" do
    { "sign in" => new_user_session_path,
      "forgot password" => new_user_password_path }
      .each { |label, path| assert_no_leaked_syntax(label, path) }
  end
end
