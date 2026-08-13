# frozen_string_literal: true

require "test_helper"

# A column of dashes is not a column.
#
# `.table-no-permission` means "no action on *this* row", which says something only when another row has
# one. When every row is a dash the column is an unlabelled strip of italic hyphens, and the reader is told
# a permission varies when it does not.
#
# design.md has had this rule since `classrooms#index` shipped one, and `portfolios#show` was written into
# `table_consistency_test` as its exception - "the dash convention stays where a column holds actions for
# some rows and not others - portfolios#show". That was wrong about that table and nobody checked: `Trade`
# is gated on the **viewer** being a student, not on anything about the row, so the column is all links or
# all dashes. A teacher or an admin opening a student's portfolio got five holdings and five hyphens. It was
# reported from the rendered page, months after the rule was written.
#
# So this asserts the shape rather than the page: for every table on every page below, under every role that
# can open it, no table may have as many dash cells as it has rows. It is the *ratio* that is wrong, not the
# dash.
class DashColumnTest < ActionDispatch::IntegrationTest
  # A student with holdings, their teacher, and an admin - the three viewers a portfolio has.
  def a_student_with_holdings
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    2.times { create(:portfolio_stock, portfolio: student.portfolio, stock: create(:stock), shares: 2) }
    student
  end

  def assert_no_all_dash_column(path, who)
    get path

    assert_response :success, "#{who} could not open #{path}"

    response.parsed_body.css("table").each_with_index do |table, i|
      rows = table.css("tbody tr").size
      dashes = table.css(".table-no-permission").size
      next if rows.zero? || dashes.zero?

      assert_operator dashes, :<, rows,
                      "#{path} as #{who}: table #{i + 1} has #{dashes} dashes in #{rows} rows. If no row " \
                      "has an action, drop the column - the header, the cells, and one from the empty " \
                      "state's colspan."
    end
  end

  test "no table shows a dash on every row" do
    student = a_student_with_holdings
    classroom = student.classroom
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    portfolio_path = user_portfolio_path(student, student.portfolio)

    # `/classrooms` is `teacher_or_admin?`, so a student is not offered it at all.
    { "the student themselves" => [student, [portfolio_path, stocks_path]],
      "their teacher" => [teacher, [portfolio_path, classrooms_path, stocks_path]],
      "an admin" => [create(:admin, admin: true, classroom: nil),
                     [portfolio_path, classrooms_path, stocks_path]] }.each do |who, (user, paths)|
      sign_in(user)
      paths.each { |path| assert_no_all_dash_column(path, who) }
      sign_out(user)
    end
  end

  # The other half of the fix, so it cannot be read as "delete the column". The owner keeps it: every one of
  # their rows has a Trade link, which is what makes the column worth a header.
  test "the owner still gets the holdings actions column" do
    student = a_student_with_holdings
    sign_in(student)

    get user_portfolio_path(student, student.portfolio)

    assert_response :success
    table = response.parsed_body.at_css("[data-testid='holdings-table'] table")
    rows = table.css("tbody tr").size
    # Scoped to the trailing cell: below `lg` a row's actions are rendered a second time inside the primary
    # cell, and a request test has no CSS, so an unscoped count is double.
    trades = table.css("td.table-actions-cell a").count { |a| a.text.strip.start_with?("Trade") }

    assert_operator rows, :>, 0, "no holdings to check"
    assert_equal rows, trades, "every holding a student owns is one they can trade"
    assert_empty table.css(".table-no-permission"), "and none of them shows the no-permission dash"
  end

  # The admin tables, which use no dash today. Cheap to keep honest, and the check costs one request each.
  test "no admin table shows a dash on every row" do
    classroom = create(:classroom)
    create(:student, classroom:)
    create(:teacher)
    create(:stock)
    create(:school)
    sign_in(create(:admin, admin: true, classroom: nil))

    [admin_classrooms_path, admin_students_path, admin_teachers_path, admin_users_path,
     admin_stocks_path, admin_schools_path, admin_school_years_path].each do |path|
      assert_no_all_dash_column(path, "an admin")
    end
  end

  # **There is no reachable mixed column left in the app**, which is worth writing down rather than
  # discovering again. `classrooms#index` keeps a dash branch and it cannot fire: `ClassroomPolicy::Scope`
  # gives a teacher only the classrooms they teach and `edit?` permits exactly those, so every row a teacher
  # sees is editable, and an admin may edit all of them. The branch is a guard against a future scope that
  # returns more, and `actions_column` already stops it becoming a column of hyphens.
  #
  # So this asserts the live behaviour instead: a teacher sees the column *and* an action on every row.
  test "a teacher's classrooms table has an action on every row it shows" do
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom: create(:classroom, :with_trading, name: "Theirs"))
    create(:classroom, :with_trading, name: "Somebody else's")
    sign_in(teacher)

    get classrooms_path

    assert_response :success
    table = response.parsed_body.at_css("table")
    rows = table.css("tbody tr").size

    assert_operator rows, :>, 0, "the teacher should see the classroom they teach"
    assert_equal rows, table.css("td.table-actions-cell a").count { |a| a.text.strip == "Edit" },
                 "every row a teacher is shown is one they can edit, so no row needs the dash"
    assert_empty table.css(".table-no-permission")
  end
end
