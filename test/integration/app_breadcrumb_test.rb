# frozen_string_literal: true

require "test_helper"

# The app half's breadcrumb trail.
#
# It had none. Trails were an admin convention - `shared/_breadcrumbs` lived under `admin/` - so every page
# on this half that is reached *from* somewhere left the reader with the browser's Back button: a stock from
# the trading floor, a classroom from Classes, a grade book and both student forms from a classroom, and a
# portfolio from either a classroom roster or an admin record. Reported on the portfolio, and it was eight
# pages.
#
# The rule is unchanged and shared: `shared/_breadcrumbs` drops itself below two crumbs, so a page whose only
# parent is a navbar item renders nothing. That is why `home`, `stocks#index`, `orders#index`,
# `classrooms#index`, `profiles#edit` and `announcements#show` have no trail, and why the owner of a
# portfolio has none while a teacher and an admin do.
class AppBreadcrumbTest < ActionDispatch::IntegrationTest
  def trail
    response.parsed_body.css("nav[aria-label='Breadcrumb'] li").map { |li| li.text.strip.gsub(/\s+/, " ") }
  end

  def heading
    response.parsed_body.at_css("main h1")&.text&.strip
  end

  def a_class_with_a_student
    classroom = create(:classroom, :with_trading, name: "Period 3")
    student = create(:student, :with_portfolio, classroom:, name: "Robin Fields")
    [classroom, student.reload]
  end

  test "a teacher's pages name the classroom they came from" do
    classroom, student = a_class_with_a_student
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    grade_book = create(:grade_book, classroom:)
    sign_in(teacher)

    { classroom_path(classroom) => ["Home", "Classes", "Period 3"],
      edit_classroom_path(classroom) => ["Home", "Classes", "Period 3", "Edit classroom"],
      new_classroom_student_path(classroom) => ["Home", "Classes", "Period 3", "Add new student"],
      edit_classroom_student_path(classroom, student) => ["Home", "Classes", "Period 3", "Edit student"],
      classroom_grade_book_path(classroom, grade_book) => ["Home", "Classes", "Period 3",
                                                           grade_book.quarter.name],
      user_portfolio_path(student, student.portfolio) => ["Home", "Classes", "Period 3",
                                                          "Robin Fields's portfolio"] }.each do |path, want|
      get path

      assert_response :success, "a teacher could not open #{path}"
      assert_equal want, trail, "#{path} trail"
      assert_equal want.last, heading, "#{path}: the last crumb is the page's own title"
    end
  end

  # An admin arrives at a portfolio from the student's **admin** record, so their trail roots at the
  # dashboard and every crumb goes back where they were. Rooting it at Home would name a page not on their
  # path.
  test "an admin's portfolio trail leads back into the admin half" do
    _classroom, student = a_class_with_a_student
    sign_in(create(:admin, admin: true, classroom: nil))

    get user_portfolio_path(student, student.portfolio)

    assert_response :success
    assert_equal ["Dashboard", "Students", "Robin Fields", "Robin Fields's portfolio"], trail
    assert_equal admin_student_path(student), response.parsed_body.css("nav[aria-label='Breadcrumb'] a")
      .find { |a| a.text.strip == "Robin Fields" }["href"]
  end

  test "a student gets a trail on a stock and none on their own portfolio" do
    _classroom, student = a_class_with_a_student
    stock = create(:stock, ticker: "AAPL")
    sign_in(student)

    get stock_path(stock)

    assert_response :success
    assert_equal ["Home", "Trading floor", "AAPL"], trail
    assert_equal "AAPL", heading

    get user_portfolio_path(student, student.portfolio)

    assert_response :success
    assert_empty trail, "the owner's portfolio is a navbar item, so it is top-level for them"
  end

  # The pages whose only parent is a navbar item. A trail there is the page's own name twice, which is the
  # defect that removed every admin index's trail.
  test "a page reached from the navbar has no trail" do
    create(:stock)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom: create(:classroom, :with_trading))
    sign_in(teacher)

    [root_path, stocks_path, orders_path, classrooms_path, edit_profile_path].each do |path|
      get path

      assert_response :success
      assert_empty trail, "#{path} is reached from the navbar and needs no trail"
    end
  end
end
