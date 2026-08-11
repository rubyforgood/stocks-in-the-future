# frozen_string_literal: true

require "test_helper"

module Admin
  class SchoolYearsControllerTest < ActionDispatch::IntegrationTest
    test "index" do
      create(:school_year)
      create(:school_year)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_school_years_path

      assert_response :success
      assert_select "h1", "School years"
      assert_select "tbody tr", count: 2
    end

    test "show" do
      school_name = "Candy Kingdom"
      year_name = "1000"
      school = create(:school, name: school_name)
      year = create(:year, name: year_name)
      school_year = create(:school_year, school:, year:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_school_year_path(school_year)

      assert_response :success
      assert_select "h1", "#{school_name} (#{year_name})"
      # **No "Quarters" card.** A school year always has exactly four, so listing them was an invariant
      # rendered as data. The count is in the summary line instead.
      assert_select "h2", text: "Quarters", count: 0
      assert_select "p", text: /4 quarters/
    end

    test "new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_school_year_path

      assert_response :success
      assert_select "h1", "New school year"
    end

    test "create" do
      school = create(:school)
      year = create(:year)
      params = { school_year: { school_id: school.id, year_id: year.id } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("SchoolYear.count") do
        post(admin_school_years_path, params:)
      end
      school_year = SchoolYear.last

      assert_redirected_to admin_school_year_path(school_year)
      assert_equal "School year created successfully.", flash[:notice]
      assert_equal(
        ["Quarter 1", "Quarter 2", "Quarter 3", "Quarter 4"],
        school_year.quarters.order(:number).pluck(:name)
      )
    end

    test "create with invalid params" do
      params = { school_year: { school_id: "" } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("SchoolYear.count") do
        post(admin_school_years_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "create with duplicate school year shows error" do
      school = create(:school)
      year = create(:year)
      create(:school_year, school:, year:)
      params = { school_year: { school_id: school.id, year_id: year.id } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("SchoolYear.count") do
        post(admin_school_years_path, params:)
      end

      assert_response :unprocessable_content
      # In the error summary, which is where every admin form lists its errors now - including the ones
      # on :base. This asserted `p.text-red-600`, the markup of a builder method that existed only to
      # render base errors and was a second copy of the same list.
      # The model's message now, not a base error built by hand in the controller: the same rule is
      # reached from a school's own page, so it had to live on the record.
      assert_select "[data-testid=?] li", "form-errors", /already added to this school/
    end

    test "edit" do
      school_year = create(:school_year)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_school_year_path(school_year)

      assert_response :success
      # The record's page edits in place, so its heading is the record's name.
      assert_select "h1", school_year.name
    end

    test "update" do
      school_year = create(:school_year)
      school = create(:school)
      params = { school_year: { school_id: school.id } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_school_year_path(school_year), params:)
      school_year.reload

      assert_redirected_to admin_school_year_path(school_year)
      assert_equal "School year updated successfully.", flash[:notice]
      assert_equal school.id, school_year.school_id
    end

    test "update with invalid params" do
      school_year = create(:school_year)
      params = { school_year: { school_id: nil } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_school_year_path(school_year), params:)

      assert_response :unprocessable_content
    end

    test "destroy" do
      school_year = create(:school_year)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("SchoolYear.count", -1) do
        delete admin_school_year_path(school_year)
      end

      assert_redirected_to admin_school_years_path
      assert_equal "School year deleted successfully.", flash[:notice]
    end

    test "destroy with classrooms" do
      school_year = create(:school_year)
      create(:classroom, school_year:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("SchoolYear.count") do
        delete admin_school_year_path(school_year)
      end

      assert_redirected_to admin_school_years_path
      assert_match(/Cannot delete school/, flash[:alert])
    end
  end
end
