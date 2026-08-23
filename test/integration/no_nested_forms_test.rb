# frozen_string_literal: true

require "test_helper"

# No page renders a `<form>` inside another `<form>`.
#
# `button_to` renders a whole form. The browser **drops** a nested one during parsing, and the button then
# silently submits the *outer* form to the outer form's action - it looks right, renders right, and passes
# a controller test that posts to the route directly. That has already broken a page here once, which is
# why converting the action links from `link_to` to `button_to` needed this guard written first rather
# than a careful reading afterwards.
#
# **Scanned on the raw body, not the parsed document.** Nokogiri drops the nested form exactly as a browser
# does, so a parsed tree can never show the bug - `assert_select` would find one form and report health.
class NoNestedFormsTest < ActionDispatch::IntegrationTest
  FORM_TAG = %r{<form\b|</form>}i

  def nested_form_at(html)
    depth = 0
    html.scan(FORM_TAG) do
      if Regexp.last_match(0).start_with?("</")
        depth -= 1
      else
        depth += 1
        return Regexp.last_match.offset(0).first if depth > 1
      end
    end
    nil
  end

  def assert_no_nested_forms(label, path)
    get path

    assert_response :success, "#{label} did not render"
    at = nested_form_at(response.body)

    assert_nil at,
               "#{label} nests a <form> inside another, near: " \
               "#{response.body[[at.to_i - 160, 0].max, 320].to_s.gsub(/\s+/, ' ')}"
  end

  test "the guard finds a nested form when there is one" do
    assert nested_form_at("<form><div><form></form></div></form>"), "the scanner cannot see a nested form"
    assert_nil nested_form_at("<form></form><form></form>"), "two siblings are not nested"
  end

  test "no page a student is shown nests a form" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500_000)
    stock = create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241)
    create(:portfolio_stock, portfolio: student.portfolio, stock:, shares: 2)
    create(:order, user: student, stock:, shares: 1, status: :pending, action: :buy)
    sign_in student

    { "home" => root_path, "stocks" => stocks_path, "orders" => orders_path,
      "portfolio" => user_portfolio_path(student, student.portfolio) }
      .each { |label, path| assert_no_nested_forms(label, path) }
  end

  test "no page a teacher is shown nests a form" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    book = classroom.grade_books.first
    create(:grade_entry, grade_book: book, user: student)
    sign_in teacher

    { "classrooms" => classrooms_path, "classroom" => classroom_path(classroom),
      "classroom edit" => edit_classroom_path(classroom),
      "grade book" => classroom_grade_book_path(classroom, book) }
      .each { |label, path| assert_no_nested_forms(label, path) }
  end

  test "no admin page nests a form" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500_000)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    stock = create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241)
    announcement = Announcement.create!(title: "Notice", content: "Body.")
    sign_in create(:admin)

    { "dashboard" => admin_root_path, "users" => admin_users_path,
      "user" => admin_user_path(student), "user edit" => edit_admin_user_path(student),
      "classrooms" => admin_classrooms_path, "classroom" => admin_classroom_path(classroom),
      "students" => admin_students_path, "student" => admin_student_path(student),
      "teachers" => admin_teachers_path, "teacher" => admin_teacher_path(teacher),
      "teacher edit" => edit_admin_teacher_path(teacher),
      "stocks" => admin_stocks_path, "stock" => admin_stock_path(stock),
      "announcements" => admin_announcements_path,
      "announcement" => admin_announcement_path(announcement),
      "transactions" => admin_portfolio_transactions_path,
      "schools" => admin_schools_path, "school" => admin_school_path(school),
      "school years" => admin_school_years_path,
      "school year" => admin_school_year_path(school_year) }
      .each { |label, path| assert_no_nested_forms(label, path) }
  end
end
