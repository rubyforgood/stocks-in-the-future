# frozen_string_literal: true

require "test_helper"

# The app nav and the admin nav share one treatment (NavHelper) so moving between them is not
# a change of scenery. The admin nav previously had no selected state at all.
#
# The interesting case is Dashboard: /admin is a prefix of every admin path, so "inside this
# section" lit it up on every page until nav_section_active? took an exact: option.
class NavSelectedStateTest < ActionDispatch::IntegrationTest
  SELECTED = "[aria-current='page']"

  # The layout renders the nav twice, desktop and mobile, so labels are counted uniquely.
  def selected_labels(scope)
    response.parsed_body.css("#{scope} #{SELECTED}").map { |el| el.text.split.join(" ") }.uniq
  end

  test "an admin section page marks only that section" do
    sign_in(create(:admin))
    create(:student, classroom: create(:classroom))

    get admin_students_path

    assert_response :success
    assert_equal ["Students"], selected_labels("nav")
  end

  test "the admin dashboard marks only Dashboard" do
    sign_in(create(:admin))

    get admin_root_path

    assert_response :success
    assert_equal ["Dashboard"], selected_labels("nav")
  end

  test "an admin show page keeps its parent section marked" do
    classroom = create(:classroom)
    sign_in(create(:admin))

    get admin_classroom_path(classroom)

    assert_response :success
    assert_equal ["Classrooms"], selected_labels("nav")
  end

  test "the app nav marks the current destination" do
    sign_in(create(:student, :with_portfolio))

    get orders_path

    assert_response :success
    assert_equal ["Transactions"], selected_labels("nav[aria-label='Main']")
  end

  test "both navs use the same selected treatment" do
    sign_in(create(:admin))

    get admin_students_path
    admin_row = response.parsed_body.at_css("nav #{SELECTED}")

    get orders_path
    app_row = response.parsed_body.at_css("nav[aria-label='Main'] #{SELECTED}")

    assert_not_nil admin_row
    assert_not_nil app_row
    assert_includes admin_row["class"], "bg-sitf-primary/10"
    assert_includes app_row["class"], "bg-sitf-primary/10"
  end

  test "the sidebar is no longer a dark panel" do
    sign_in(create(:student, :with_portfolio))

    get root_path

    nav = response.parsed_body.at_css("nav[aria-label='Main'] > div")

    assert_not_nil nav
    assert_includes nav["class"], "bg-white"
    assert_not_includes nav["class"], "bg-sitf-primary"
  end
end
