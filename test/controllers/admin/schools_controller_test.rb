# frozen_string_literal: true

require "test_helper"

module Admin
  class SchoolsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin, admin: true, classroom: nil)
      sign_in(@admin)
    end

    test "index" do
      create(:school, name: "Alpha School")
      create(:school, name: "Beta School")

      get admin_schools_path

      assert_response :success
      assert_select "h1", "Schools"
      assert_select "tbody tr", count: 2
    end

    test "show" do
      school = create(:school, name: "Test School")

      get admin_school_path(school)

      assert_response :success
      assert_select "h1", school.name
    end

    test "show lists the school's years with what each one holds" do
      year = a_year(0)
      school = create(:school)
      school_year = SchoolYear.create!(school:, year:)
      create(:classroom, school_year:, name: "Sixth grade")

      get admin_school_path(school)

      assert_response :success
      assert_select "[data-testid='school-years']"
      assert_select "[data-testid='school-years']", text: /#{year.name}/
      # Four quarters are provisioned on create, and the row says so - that is the consequence a removal
      # has to warn about.
      assert_select "[data-testid='school-years']", text: /4 quarters/
      assert_select "[data-testid='school-years']", text: /1 classroom/
    end

    test "new" do
      get new_admin_school_path

      assert_response :success
      assert_select "h1", "New school"
    end

    # Relative to the current school year, never hardcoded: the window moves, and a literal "2024 - 2025"
    # here would have started failing in July whichever way this was written.
    def a_year(offset)
      start = Year.current_school_year_name.split(" - ").first.to_i + offset
      create(:year, name: "#{start} - #{start + 1}")
    end

    # On the **edit** page: the show page renders the same list read-only. Managing a record's collection on
    # its show page while the edit page held only a name field was reported as friction, correctly.
    test "the add control offers every year the school does not have, newest first" do
      distant = a_year(-6)
      current = a_year(0)
      following = a_year(1)
      school = create(:school)
      SchoolYear.create!(school:, year: following)

      get edit_admin_school_path(school)

      options = css_select("select[name='year_id'] option").map(&:text)

      assert_includes options, "#{current.name} (current)", "the current year is marked in the option text"
      assert_includes options, distant.name, "a select carries the whole list, so no year is unreachable"
      assert_not_includes options, following.name, "already added"
    end

    test "a year already added is not offered twice" do
      year = a_year(0)
      school = create(:school)
      SchoolYear.create!(school:, year:)

      get edit_admin_school_path(school)

      assert_select "select[name='year_id'] option", text: /#{year.name}/, count: 0
    end

    # **The guard against silent data loss.** `year_ids=` replaces the whole collection, so a school linked
    # to a year outside the window would have that association destroyed by any save from a form that never
    # showed it - along with the four quarters on the `SchoolYear`, or a failure if it has classrooms, since
    # both are `restrict_with_error`.
    # The edit form no longer touches years at all, which is what removed the two defects: unchecking a box
    # silently destroyed four quarters, and doing it to a year with a classroom raised a foreign-key
    # violation.
    # The *form* does not post years; the page manages them through their own actions beside it.
    test "the edit form does not post year_ids" do
      school = create(:school)
      SchoolYear.create!(school:, year: a_year(0))

      get edit_admin_school_path(school)

      assert_select "input[name='school[year_ids][]']", count: 0
    end

    test "create" do
      params = { school: { name: "New School" } }

      assert_difference("School.count") do
        post(admin_schools_path, params:)
      end

      school = School.last

      assert_redirected_to admin_school_path(school)
      assert_equal "School created successfully.", flash[:notice]
      assert_empty school.years, "a school's years are provisioned afterwards, one at a time"
    end

    test "create without years" do
      params = {
        school: {
          name: "School Without Years"
        }
      }

      assert_difference("School.count") do
        post(admin_schools_path, params:)
      end

      school = School.last
      assert_redirected_to admin_school_path(school)
      assert_empty school.years
    end

    test "create with invalid params" do
      params = {
        school: {
          name: ""
        }
      }

      assert_no_difference("School.count") do
        post(admin_schools_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "edit" do
      school = create(:school, name: "Test School")

      get edit_admin_school_path(school)

      assert_response :success
      assert_select "h1", "Edit school"
    end

    test "update" do
      year = a_year(0)
      school = create(:school, name: "Original Name")
      SchoolYear.create!(school:, year:)

      patch admin_school_path(school), params: { school: { name: "Updated Name" } }
      school.reload

      assert_redirected_to admin_school_path(school)
      assert_equal "School updated successfully.", flash[:notice]
      assert_equal "Updated Name", school.name
      assert_equal [year], school.years, "editing the name leaves the school's years alone"
    end

    # `year_ids` is no longer permitted, so a form post cannot remove a year - which is the point. Removal
    # goes through its own action, where it can refuse and say why.
    test "update cannot remove years" do
      year = a_year(0)
      school = create(:school, name: "Test School")
      SchoolYear.create!(school:, year:)

      patch admin_school_path(school), params: { school: { name: school.name, year_ids: [""] } }

      assert_redirected_to admin_school_path(school)
      assert_equal [year.id], school.reload.year_ids
    end

    test "update with invalid params" do
      school = create(:school, name: "Test School")
      params = { school: { name: "" } }

      patch(admin_school_path(school), params:)

      assert_response :unprocessable_content
    end

    test "destroy" do
      school = create(:school, name: "Test School")

      assert_difference("School.count", -1) do
        delete admin_school_path(school)
      end

      assert_redirected_to admin_schools_path
    end

    test "cannot destroy school with associated years" do
      school = create(:school, name: "Test School")
      school.years << create(:year, name: "2025 - 2026")

      assert_no_difference("School.count") do
        delete admin_school_path(school)
      end
    end
  end
end
