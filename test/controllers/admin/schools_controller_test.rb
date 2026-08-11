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

    test "show displays associated years" do
      school = create(:school, name: "Test School")
      year1 = create(:year, name: "2024 - 2025")
      year2 = create(:year, name: "2025 - 2026")
      school.years << [year1, year2]

      get admin_school_path(school)

      assert_response :success
      assert_select "li", text: year1.name
      assert_select "li", text: year2.name
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

    test "new offers the current school year, the one either side, and nothing further out" do
      previous = a_year(-1)
      current = a_year(0)
      following = a_year(1)
      distant = a_year(5)

      get new_admin_school_path

      assert_response :success
      assert_select "input[type='checkbox'][name='school[year_ids][]']", count: 3
      [previous, current, following].each { |year| assert_select "label", text: /#{year.name}/ }
      assert_select "label", text: /#{distant.name}/, count: 0
    end

    test "the current school year is marked" do
      a_year(0)

      get new_admin_school_path

      assert_select "label", text: /Current/
    end

    # **The guard against silent data loss.** `year_ids=` replaces the whole collection, so a school linked
    # to a year outside the window would have that association destroyed by any save from a form that never
    # showed it - along with the four quarters on the `SchoolYear`, or a failure if it has classrooms, since
    # both are `restrict_with_error`.
    test "edit still offers a year the school already has, however old" do
      distant = a_year(-6)
      a_year(0)
      school = create(:school)
      create(:school_year, school:, year: distant)

      get edit_admin_school_path(school)

      assert_select "label", text: /#{distant.name}/
      assert_select "input[type='checkbox'][name='school[year_ids][]'][checked]", count: 1
    end

    test "create" do
      year1 = create(:year, name: "2024 - 2025")
      year2 = create(:year, name: "2025 - 2026")
      params = {
        school: {
          name: "New School",
          year_ids: [year1.id, year2.id]
        }
      }

      assert_difference("School.count") do
        post(admin_schools_path, params:)
      end

      school = School.last
      assert_redirected_to admin_school_path(school)
      assert_equal "School created successfully.", flash[:notice]
      assert_equal [year1, year2].sort_by(&:id), school.years.sort_by(&:id)
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

    test "edit shows current year selections" do
      year1 = create(:year, name: "2024 - 2025")
      year2 = create(:year, name: "2025 - 2026")
      school = create(:school, name: "Test School")
      school.years << year1

      get edit_admin_school_path(school)

      assert_response :success
      assert_select "input[type='checkbox'][name='school[year_ids][]'][value='#{year1.id}'][checked='checked']"
      assert_select "input[type='checkbox'][name='school[year_ids][]'][value='#{year2.id}']:not([checked])"
    end

    test "update" do
      year1 = create(:year, name: "2024 - 2025")
      year2 = create(:year, name: "2025 - 2026")
      school = create(:school, name: "Original Name")
      school.years << year1
      params = {
        school: {
          name: "Updated Name",
          year_ids: [year2.id]
        }
      }

      patch(admin_school_path(school), params:)
      school.reload

      assert_redirected_to admin_school_path(school)
      assert_equal "School updated successfully.", flash[:notice]
      assert_equal "Updated Name", school.name
      assert_equal [year2], school.years
    end

    test "update can remove all years" do
      year1 = create(:year, name: "2024 - 2025")
      school = create(:school, name: "Test School")
      school.years << year1
      params = {
        school: {
          name: school.name,
          year_ids: []
        }
      }

      patch(admin_school_path(school), params:)
      school.reload

      assert_redirected_to admin_school_path(school)
      assert_empty school.years
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
