# frozen_string_literal: true

require "test_helper"

# The last crumb names the record the way its own page does.
#
# `admin/school_years#show` set its crumb to `@school_year.to_s`. `SchoolYear` defines `#name` and no `#to_s`,
# so the trail read **`Dashboard / School years / #<SchoolYear:0x0000ffff68492f88>`** while the h1 above it
# read "Test School (2026 - 2027)". Reported by a reader, and nothing in the suite looked at a crumb's text.
#
# Two more were the same fault from the other side, wrong rather than broken: teachers put the *username* in
# the trail under an h1 showing the display name, and stocks the *ticker* under the company name. A trail
# whose last item disagrees with the page it is on cannot be used to tell where you are, which is the only
# thing a trail is for.
class BreadcrumbLabelTest < ActionDispatch::IntegrationTest
  # The record pages, one of each type. `admin/schools#show` builds its own wrapper rather than rendering
  # `_record_page`, and is in the list for exactly that reason.
  def record_pages
    school = create(:school, name: "Hampstead Hill")
    year = Year.current_school_year.first_or_create!(name: Year.current_school_year_name)
    school_year = create(:school_year, school:, year:)
    classroom = create(:classroom, school_year:)
    student = create(:student, classroom:, name: "Robin Fields")

    { admin_school_path(school) => "schools",
      admin_school_year_path(school_year) => "school years",
      admin_classroom_path(classroom) => "classrooms",
      admin_student_path(student) => "students",
      admin_teacher_path(create(:teacher, name: "Alex Rivers")) => "teachers",
      admin_user_path(create(:admin, admin: false, classroom: nil)) => "users",
      admin_stock_path(create(:stock)) => "stocks",
      admin_announcement_path(Announcement.create!(title: "Notice", content: "Body")) => "announcements" }
  end

  test "the last breadcrumb is the page's own title" do
    sign_in(create(:admin, admin: true, classroom: nil))

    record_pages.each do |path, name|
      get path

      assert_response :success

      crumbs = response.parsed_body.css("nav[aria-label='Breadcrumb'] li").map { |li| li.text.strip }
      heading = response.parsed_body.at_css("main h1")&.text&.strip

      assert_predicate crumbs, :any?, "#{name}: no breadcrumb trail to check"
      assert heading, "#{name}: no h1 to compare the trail against"
      assert_equal heading, crumbs.last,
                   "#{name}: the trail ends \"#{crumbs.last}\" under an h1 reading \"#{heading}\""
    end
  end

  # The shape the original bug took, named on its own so a regression reads as what it is rather than as a
  # copy mismatch. `#<Model:0x...>` is what `to_s` returns for any record without an override.
  test "no breadcrumb renders a record's inspect string" do
    sign_in(create(:admin, admin: true, classroom: nil))

    record_pages.each_key do |path|
      get path

      assert_response :success
      assert_no_match(
        /#<[A-Z]\w*:0x/, response.parsed_body.text,
        "#{path} renders a bare object; a label is being set to a record rather than to a name"
      )
    end
  end
end
