# frozen_string_literal: true

require "test_helper"

module AdminV2
  class SchoolYearsControllerTest < ActionDispatch::IntegrationTest
    test "index" do
      create(:school_year)
      create(:school_year)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_school_years_path

      assert_response :success
      assert_select "h3", "School Years"
      assert_select "tbody tr", count: 2
    end

    test "show" do
      school_name = "Candy Kingdom"
      year_name = "1000"
      school = create(:school, name: school_name)
      year = create(:year, name: year_name)
      school_year = create(:school_year, school:, year:)
      create(:quarter, school_year:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get admin_v2_school_year_path(school_year)

      assert_response :success
      assert_select "h2", "#{school_name} (#{year_name})"
      assert_select "h3", "Quarters"
    end

    test "new" do
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get new_admin_v2_school_year_path

      assert_response :success
      assert_select "h1", "New School Year"
    end

    test "create" do
      school = create(:school)
      year = create(:year)
      params = { school_year: { school_id: school.id, year_id: year.id } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("SchoolYear.count") do
        post(admin_v2_school_years_path, params:)
      end
      school_year = SchoolYear.last

      assert_redirected_to admin_v2_school_year_path(school_year)
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
        post(admin_v2_school_years_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "edit" do
      school_year = create(:school_year)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      get edit_admin_v2_school_year_path(school_year)

      assert_response :success
      assert_select "h1", "Edit School Year"
    end

    test "update" do
      school_year = create(:school_year)
      school = create(:school)
      params = { school_year: { school_id: school.id } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_v2_school_year_path(school_year), params:)
      school_year.reload

      assert_redirected_to admin_v2_school_year_path(school_year)
      assert_equal "School year updated successfully.", flash[:notice]
      assert_equal school.id, school_year.school_id
    end

    test "update with invalid params" do
      school_year = create(:school_year)
      params = { school_year: { school_id: nil } }
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      patch(admin_v2_school_year_path(school_year), params:)

      assert_response :unprocessable_content
    end

    test "destroy" do
      school_year = create(:school_year)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_difference("SchoolYear.count", -1) do
        delete admin_v2_school_year_path(school_year)
      end

      assert_redirected_to admin_v2_school_years_path
      assert_equal "School year deleted successfully.", flash[:notice]
    end

    test "destroy with classrooms" do
      school_year = create(:school_year)
      create(:classroom, school_year:)
      admin = create(:admin, admin: true, classroom: nil)
      sign_in(admin)

      assert_no_difference("SchoolYear.count") do
        delete admin_v2_school_year_path(school_year)
      end

      assert_redirected_to admin_v2_school_years_path
      assert_match(/Cannot delete school/, flash[:alert])
    end
  end
end
