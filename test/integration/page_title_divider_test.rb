# frozen_string_literal: true

require "test_helper"

# design.md: a page title never gets a rule under it. Spacing separates a title from
# its content, and where a card or table follows immediately, a rule lands a few pixels
# from that surface's own border.
#
# This parses the rendered page and walks up from the h1 rather than pattern-matching
# the HTML, so re-nesting a heading cannot quietly turn the check into a no-op. Rules
# *inside* a bounded surface are structure and are not the subject here - the walk stops
# at the ancestor that holds the h1 and its subtitle.
class PageTitleDividerTest < ActionDispatch::IntegrationTest
  setup do
    @classroom = create(:classroom, :with_trading)
    @student = create(:student, classroom: @classroom)
    @grade_book = @classroom.grade_books.first
    create(:grade_entry, grade_book: @grade_book, user: @student)
    create(:stock)
    sign_in(create(:admin))
  end

  def pages
    {
      "portfolio" => @student.portfolio_path,
      "trading floor" => stocks_path,
      "classrooms" => classrooms_path,
      "transactions" => orders_path,
      "grade book" => classroom_grade_book_path(@classroom, @grade_book),
      "home" => root_path
    }
  end

  # Admin pages could not be checked before: their only h1 was the layout's sr-only one,
  # so "exactly one visible h1" had nothing to find. Now that the title and its actions
  # sit at page level, they can be held to the same rule as everything else.
  def admin_pages
    student = @student
    teacher = create(:teacher)
    teacher.classrooms << @classroom
    stock = create(:stock)

    {
      "admin users" => admin_users_path,
      "admin students" => admin_students_path,
      "admin teachers" => admin_teachers_path,
      "admin classrooms" => admin_classrooms_path,
      "admin school years" => admin_school_years_path,
      "admin schools" => admin_schools_path,
      "admin stocks" => admin_stocks_path,
      "admin announcements" => admin_announcements_path,
      "admin student" => admin_student_path(student),
      "admin teacher" => admin_teacher_path(teacher),
      "admin classroom" => admin_classroom_path(@classroom),
      "admin stock" => admin_stock_path(stock)
    }
  end

  test "no admin page draws a rule under its title, and each has one visible h1" do
    admin_pages.each do |name, path|
      get path

      assert_response :success, "#{name} did not render"

      headings = response.parsed_body.css("h1").reject { |h1| h1["class"].to_s.include?("sr-only") }

      assert_equal 1, headings.size, "#{name} should render exactly one visible h1"

      heading = headings.first
      [heading, heading.parent].compact.each do |element|
        classes = element["class"].to_s.split

        assert_not_includes classes, "border-b",
                            "#{name} draws a rule under its title, on <#{element.name}>"
      end
    end
  end

  test "no page draws a rule under its title" do
    pages.each do |name, path|
      get path

      assert_response :success, "#{name} did not render"

      # parsed_body is a Nokogiri document for an HTML response.
      headings = response.parsed_body.css("h1").reject { |h1| h1["class"].to_s.include?("sr-only") }

      assert_equal 1, headings.size, "#{name} should render exactly one visible h1"

      heading = headings.first
      [heading, heading.parent].compact.each do |element|
        classes = element["class"].to_s.split

        assert_not_includes classes, "border-b",
                            "#{name} draws a rule under its title, on <#{element.name} class=\"#{element['class']}\">"
      end
    end
  end
end
