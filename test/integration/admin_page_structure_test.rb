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

  # The card is the rounded surface wrapping the table.
  def table_card
    table = response.parsed_body.at_css("table")

    assert_not_nil table, "expected a table on the page"

    card = table.ancestors.find { |node| node["class"].to_s.split.include?("rounded-lg") }

    assert_not_nil card, "expected the table to sit inside a rounded-lg card"
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

  test "filter tabs sit above the table card, not inside it" do
    [admin_students_path, admin_teachers_path].each do |path|
      get path

      selected = response.parsed_body.css("[aria-current='page']")

      assert_equal 1, selected.size, "#{path} should mark exactly one selected filter tab"
      assert_empty table_card.css("[aria-current='page']"),
                   "#{path} still renders its filter tabs inside the table card"
    end
  end
end
