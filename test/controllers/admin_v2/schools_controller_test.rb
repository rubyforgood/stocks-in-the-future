# frozen_string_literal: true

require "test_helper"

module AdminV2
  class SchoolsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin, admin: true, classroom: nil)
      sign_in(@admin)
    end

    test "index" do
      create(:school, name: "Alpha School")
      create(:school, name: "Beta School")

      get admin_v2_schools_path

      assert_response :success
      assert_select "h3", "Schools"
      assert_select "tbody tr", count: 2
    end

    test "show" do
      school = create(:school, name: "Test School")

      get admin_v2_school_path(school)

      assert_response :success
      assert_select "h2", school.name
    end

    test "show displays associated years" do
      school = create(:school, name: "Test School")
      year1 = create(:year, name: "2024 - 2025")
      year2 = create(:year, name: "2025 - 2026")
      school.years << [year1, year2]

      get admin_v2_school_path(school)

      assert_response :success
      assert_select "li", text: year1.name
      assert_select "li", text: year2.name
    end

    test "new" do
      get new_admin_v2_school_path

      assert_response :success
      assert_select "h1", "New School"
    end

    test "new shows year checkboxes" do
      year1 = create(:year, name: "2024 - 2025")
      year2 = create(:year, name: "2025 - 2026")

      get new_admin_v2_school_path

      assert_response :success
      assert_select "input[type='checkbox'][name='school[year_ids][]']", count: 2
      assert_select "label", text: year1.name
      assert_select "label", text: year2.name
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
        post(admin_v2_schools_path, params:)
      end

      school = School.last
      assert_redirected_to admin_v2_school_path(school)
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
        post(admin_v2_schools_path, params:)
      end

      school = School.last
      assert_redirected_to admin_v2_school_path(school)
      assert_empty school.years
    end

    test "create with invalid params" do
      params = {
        school: {
          name: ""
        }
      }

      assert_no_difference("School.count") do
        post(admin_v2_schools_path, params:)
      end

      assert_response :unprocessable_content
    end

    test "edit" do
      school = create(:school, name: "Test School")

      get edit_admin_v2_school_path(school)

      assert_response :success
      assert_select "h1", "Edit School"
    end

    test "edit shows current year selections" do
      year1 = create(:year, name: "2024 - 2025")
      year2 = create(:year, name: "2025 - 2026")
      school = create(:school, name: "Test School")
      school.years << year1

      get edit_admin_v2_school_path(school)

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

      patch(admin_v2_school_path(school), params:)
      school.reload

      assert_redirected_to admin_v2_school_path(school)
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

      patch(admin_v2_school_path(school), params:)
      school.reload

      assert_redirected_to admin_v2_school_path(school)
      assert_empty school.years
    end

    test "update with invalid params" do
      school = create(:school, name: "Test School")
      params = { school: { name: "" } }

      patch(admin_v2_school_path(school), params:)

      assert_response :unprocessable_content
    end

    test "destroy" do
      school = create(:school, name: "Test School")

      assert_difference("School.count", -1) do
        delete admin_v2_school_path(school)
      end

      assert_redirected_to admin_v2_schools_path
    end

    test "cannot destroy school with associated years" do
      school = create(:school, name: "Test School")
      school.years << create(:year, name: "2025 - 2026")

      assert_no_difference("School.count") do
        delete admin_v2_school_path(school)
      end
    end
  end
end
