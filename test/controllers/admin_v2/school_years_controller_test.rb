# frozen_string_literal: true

require "test_helper"

module AdminV2
  class SchoolYearsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:admin, admin: true)
      sign_in(@admin)

      @school1 = create(:school, name: "Test School 1")
      @school2 = create(:school, name: "Test School 2")
      @year1 = create(:year, name: "2024")
      @year2 = create(:year, name: "2025")

      @school_year1 = SchoolYear.create!(school: @school1, year: @year1)
      @school_year2 = SchoolYear.create!(school: @school2, year: @year2)
    end

    # Index tests
    test "should get index" do
      get admin_v2_school_years_path

      assert_response :success
      assert_select "h3", "School Years"
    end

    test "index shows all school years" do
      get admin_v2_school_years_path

      assert_response :success
      assert_select "tbody tr", count: 2
    end

    # Show tests
    test "should show school_year" do
      get admin_v2_school_year_path(@school_year1)

      assert_response :success
      assert_select "h2", "#{@school_year1.school.name} (#{@school_year1.year.name})"
    end

    test "should show school_year quarters" do
      # Create quarters for the school year
      Quarter.create!(school_year: @school_year1, name: "Quarter 1", number: 1)
      Quarter.create!(school_year: @school_year1, name: "Quarter 2", number: 2)

      get admin_v2_school_year_path(@school_year1)

      assert_response :success
      assert_select "h3", "Quarters"
    end

    # New tests
    test "should get new" do
      get new_admin_v2_school_year_path

      assert_response :success
      assert_select "h1", "New School Year"
    end

    # Create tests
    test "should create school_year" do
      assert_difference("SchoolYear.count", 1) do
        assert_difference("Quarter.count", 4) do
          post admin_v2_school_years_path, params: {
            school_year: {
              school_id: @school1.id,
              year_id: @year2.id
            }
          }
        end
      end

      assert_redirected_to admin_v2_school_year_path(SchoolYear.last)
      assert_equal "School year created successfully.", flash[:notice]
    end

    test "should create quarters when creating school_year" do
      post admin_v2_school_years_path, params: {
        school_year: {
          school_id: @school1.id,
          year_id: @year2.id
        }
      }

      school_year = SchoolYear.last
      assert_equal 4, school_year.quarters.count
      assert_equal ["Quarter 1", "Quarter 2", "Quarter 3", "Quarter 4"],
                   school_year.quarters.order(:number).pluck(:name)
    end

    test "should not create school_year with duplicate combination" do
      # @school_year1 already uses @school1 + @year1 combination
      assert_no_difference("SchoolYear.count") do
        post admin_v2_school_years_path, params: {
          school_year: {
            school_id: @school1.id,
            year_id: @year1.id
          }
        }
      end

      assert_response :unprocessable_content
    end

    # Edit tests
    test "should get edit" do
      get edit_admin_v2_school_year_path(@school_year1)

      assert_response :success
      assert_select "h1", "Edit School Year"
    end

    # Update tests
    test "should update school_year" do
      patch admin_v2_school_year_path(@school_year1), params: {
        school_year: {
          school_id: @school2.id
        }
      }

      assert_redirected_to admin_v2_school_year_path(@school_year1)
      assert_equal "School year updated successfully.", flash[:notice]
      assert_equal @school2.id, @school_year1.reload.school_id
    end

    test "should not update school_year with invalid params" do
      patch admin_v2_school_year_path(@school_year1), params: {
        school_year: {
          school_id: nil
        }
      }

      assert_response :unprocessable_content
    end

    # Destroy tests
    test "should destroy school_year" do
      assert_difference("SchoolYear.count", -1) do
        delete admin_v2_school_year_path(@school_year1)
      end

      assert_redirected_to admin_v2_school_years_path
      assert_equal "School year deleted successfully.", flash[:notice]
    end

    test "should not destroy school_year with classrooms" do
      create(:classroom, school_year: @school_year1)

      assert_no_difference("SchoolYear.count") do
        delete admin_v2_school_year_path(@school_year1)
      end

      assert_redirected_to admin_v2_school_year_path(@school_year1)
      assert_match(/Cannot delete school year/, flash[:alert])
    end

    # Authorization tests
    test "non-admin cannot access index" do
      sign_out(@admin)
      teacher = create(:teacher)
      sign_in(teacher)

      get admin_v2_school_years_path

      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end
  end
end
