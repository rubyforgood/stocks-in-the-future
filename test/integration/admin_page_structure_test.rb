# frozen_string_literal: true

require "test_helper"

# design.md: the page title and its actions sit at page level, and a filter is chrome
# *above* the data rather than on its surface. So neither the heading nor the filter tabs
# may end up inside the table card.
#
# Both of those were got wrong by reasoning about them rather than reading the design
# system - the tabs were left in the card on the argument that they "belong to the table".
# This asserts the structure instead of trusting that argument.
class AdminPageStructureTest < ActionDispatch::IntegrationTest
  setup do
    @classroom = create(:classroom)
    create(:student, classroom: @classroom)
    teacher = create(:teacher)
    teacher.classrooms << @classroom
    create(:stock)
    sign_in(create(:admin))
  end

  # The card is the .tw-card surface wrapping the table. Matching the shared class rather
  # than a radius utility, so changing the surface does not silently break the check.
  def table_card
    table = response.parsed_body.at_css("table")

    assert_not_nil table, "expected a table on the page"

    card = table.ancestors.find { |node| node["class"].to_s.split.include?("tw-card") }

    assert_not_nil card, "expected the table to sit inside a .tw-card"
    card
  end

  def index_paths
    {
      "users" => admin_users_path,
      "students" => admin_students_path,
      "teachers" => admin_teachers_path,
      "classrooms" => admin_classrooms_path,
      "school years" => admin_school_years_path,
      "schools" => admin_schools_path,
      "stocks" => admin_stocks_path,
      "announcements" => admin_announcements_path
    }
  end

  test "no index page puts its heading inside the table card" do
    index_paths.each do |name, path|
      get path

      assert_response :success, "#{name} did not render"
      assert_empty table_card.css("h1, h2, h3"),
                   "#{name} still has a heading inside the table card"
    end
  end

  test "no index page puts a page-level action inside the table card" do
    # The "New ..." control belongs in the page header. Row-level View/Edit/Delete links
    # are inside the card legitimately, so this looks for the create action by name.
    { "users" => [admin_users_path, "New user"],
      "students" => [admin_students_path, "New student"],
      "teachers" => [admin_teachers_path, "New teacher"],
      "classrooms" => [admin_classrooms_path, "New classroom"],
      "school years" => [admin_school_years_path, "New school year"],
      "schools" => [admin_schools_path, "New school"],
      "stocks" => [admin_stocks_path, "New stock"],
      "announcements" => [admin_announcements_path, "New announcement"] }.each do |name, (path, label)|
      get path

      assert_includes response.body, label, "#{name} is missing its #{label.inspect} action"

      inside = table_card.css("a").select { |link| link.text.strip == label }

      assert_empty inside, "#{name} has #{label.inspect} inside the table card"
    end
  end

  # **A breadcrumb trail needs somewhere to go back to.** Every admin index rendered
  # "Dashboard > Classrooms" directly above an h1 reading "Classrooms" - the page's own name twice, and its
  # one link duplicated the sidebar's Dashboard item. Measured: 44px, taking the h1 from y=128 to y=172.
  #
  # Carbon says not to use breadcrumbs with only one level, GOV.UK shows the path above the current page so a
  # top-level page has none, and Polaris has a back action rather than a trail.
  test "an index page has no breadcrumb trail" do
    sign_in(create(:admin, admin: true, classroom: nil))

    [admin_students_path, admin_teachers_path, admin_classrooms_path, admin_schools_path,
     admin_school_years_path, admin_stocks_path, admin_announcements_path,
     admin_portfolio_transactions_path, admin_users_path].each do |path|
      get path

      assert_response :success
      assert_select "nav[aria-label=?]", "Breadcrumb", { count: 0 },
                    "#{path}: a one-level trail names the page the h1 has just named"
    end
  end

  # And a page with a parent keeps its trail, because there is something to click.
  test "a record page keeps its trail" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.reload
    sign_in(create(:admin, admin: true, classroom: nil))

    [admin_student_path(student), new_admin_student_path].each do |path|
      get path

      assert_response :success
      assert_select "nav[aria-label=?]", "Breadcrumb", { count: 1 }, "#{path}: the trail is gone"
      assert_select "nav[aria-label='Breadcrumb'] a[href=?]", admin_students_path,
                    { count: 1 }, "#{path}: the trail has no link back to the list"
    end
  end

  # **A create page has one section, so its heading is not drawn.** Reported on students#new: "the details
  # subhead pushes the content down and doesn't seem to add value". It does not - "Details" under
  # "New student" repeats the h1 a line above, and its hint repeated the submit button. Measured: the card
  # moved from y=304 to y=244, so the subhead was costing 60px of the first viewport to say nothing.
  #
  # The heading stays in the markup as `sr-only`, so the `<section aria-labelledby>` keeps its accessible
  # name. This is Polaris's rule for a card header on a page with one card, which design.md already records
  # at card level: "Teacher details" under "Edit teacher", 24px apart, in two sizes.
  test "no create page draws a section heading" do
    sign_in(create(:admin, admin: true, classroom: nil))

    [new_admin_school_path, new_admin_school_year_path, new_admin_student_path, new_admin_teacher_path,
     new_admin_user_path, new_admin_stock_path, new_admin_announcement_path,
     new_admin_portfolio_transaction_path].each do |path|
      get path

      assert_response :success
      headings = response.parsed_body.css("main section[aria-labelledby] > h2")

      assert_equal 1, headings.size, "#{path}: a create page has one section"
      assert_includes headings.first["class"].to_s, "sr-only",
                      "#{path}: the section heading is drawn, and it repeats the page title"
      assert_select "p", text: /Saved when you press/, count: 0
    end
  end

  # **Every create page says what submitting does.** Two of them said what the reader would do on some *other*
  # page instead - "You can add money and see attendance once the account exists" and "You will add its school
  # years after it exists" - which is narration, not information, and was reported as such.
  #
  # This asserts the description exists rather than that it is well written, which no test can do. What it can
  # do is catch the two shapes that were wrong: a page with nothing to say, and a fact stated twice.
  test "every create page has a description" do
    sign_in(create(:admin, admin: true, classroom: nil))

    { new_admin_school_path => /school year/,
      new_admin_school_year_path => /four quarters/,
      new_admin_student_path => /password/,
      new_admin_teacher_path => /reset email/,
      new_admin_user_path => /portfolio/,
      new_admin_stock_path => /ticker/,
      new_admin_announcement_path => /featured/,
      new_admin_portfolio_transaction_path => /moves the money/ }.each do |path, expected|
      get path

      assert_response :success
      # Scoped to the page header's own paragraph - `_page_header` puts it in the title's column - because a
      # field hint further down the form uses the same type classes, and on the announcements page it also
      # mentions "featured".
      assert_select "main div.min-w-0 > p", { text: expected, count: 1 },
                    "#{path}: the page header's description does not say what submitting does"
    end
  end

  # **An index page describes itself only where there is something to say.** Six of the nine have nothing a
  # reader cannot see - a table of students needs no sentence explaining that it lists students - and
  # inventing a line for each would be padding, which is the opposite failure to the one the create pages had.
  #
  # Three do: `users` overlaps the students and teachers pages in the same sidebar, `stocks` mixes archived
  # rows with active ones and its prices are refreshed by a job, and `portfolio_transactions` *is* what every
  # balance is derived from. This asserts both halves, because "add a description everywhere" is the wrong
  # correction and the test should say so.
  test "an index describes itself only where there is a fact to state" do
    sign_in(create(:admin, admin: true, classroom: nil))

    { admin_users_path => /students and teachers/,
      admin_stocks_path => /refresh each weekday/,
      admin_portfolio_transactions_path => /sum of their rows/ }.each do |path, expected|
      get path

      assert_response :success
      assert_select "main div.min-w-0 > p", { text: expected, count: 1 }, "#{path}: description missing"
    end

    [admin_students_path, admin_teachers_path, admin_classrooms_path,
     admin_schools_path, admin_school_years_path, admin_announcements_path].each do |path|
      get path

      assert_response :success
      assert_select "main div.min-w-0 > p", { count: 0 },
                    "#{path}: a description was added to a table that explains itself"
    end
  end

  # The teachers form stated its password behaviour twice: in the description, and again in a line below the
  # last field. One statement, where it is read before the reader starts typing.
  test "the teacher password behaviour is stated once" do
    sign_in(create(:admin, admin: true, classroom: nil))

    get new_admin_teacher_path

    assert_response :success
    assert_equal 1, response.parsed_body.text.scan(/temporary password/i).size,
                 "the temporary-password sentence appears more than once"
  end

  # And the record pages still draw theirs, because there they say which section you are in.
  test "a record page draws its section headings" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.reload
    sign_in(create(:admin, admin: true, classroom: nil))

    get admin_student_path(student)

    assert_response :success
    headings = response.parsed_body.css("main section[aria-labelledby] > h2")

    assert_operator headings.size, :>, 1
    drawn = headings.none? { |h| h["class"].to_s.include?("sr-only") }

    assert drawn, "a record page's section headings distinguish its sections and are drawn"
  end

  test "filter tabs sit above the table card, not inside it" do
    [admin_students_path, admin_teachers_path].each do |path|
      get path

      # Scoped to the rail: the sidebar nav rows carry aria-current too, so counting it
      # across the whole page measures the nav rather than the tabs.
      rail = response.parsed_body.at_css("[data-testid='filter-tabs']")

      assert_not_nil rail, "#{path} should render a filter tab rail"
      assert_equal 1, rail.css("[aria-current='page']").size,
                   "#{path} should mark exactly one selected filter tab"
      assert_empty table_card.css("[data-testid='filter-tabs']"),
                   "#{path} still renders its filter tabs inside the table card"
    end
  end
end
