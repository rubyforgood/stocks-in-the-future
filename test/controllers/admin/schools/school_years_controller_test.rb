# frozen_string_literal: true

require "test_helper"

# Adding a year to a school and taking one away.
#
# **The two defects this replaced, both measured.** The school form carried a `collection_check_boxes` on
# `year_ids`: unchecking a box silently destroyed a `SchoolYear` and the four quarters it provisions, and
# doing it to a year with a classroom raised `PG::ForeignKeyViolation` - a 500 - because the join was deleted
# before `restrict_with_error` could speak. A third was found while removing it: `update` rebuilt `year_ids`
# by hand and defaulted it to `[]`, so with the checkboxes gone every name edit would have wiped the lot.
class SchoolYearProvisioningTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @school = create(:school)
    @year = create(:year, name: "2100 - 2101")
    sign_in create(:admin, admin: true, classroom: nil)
  end

  test "adding a year provisions its quarters and says so" do
    assert_difference("SchoolYear.count", 1) do
      assert_difference("Quarter.count", 4) do
        post admin_school_school_years_path(@school), params: { year_id: @year.id }
      end
    end

    assert_redirected_to admin_school_path(@school)
    assert_equal "2100 - 2101 added, with 4 quarters.", flash[:notice]
  end

  test "adding the same year twice is a message, not a database error" do
    SchoolYear.create!(school: @school, year: @year)

    assert_no_difference("SchoolYear.count") do
      post admin_school_school_years_path(@school), params: { year_id: @year.id }
    end

    assert_equal "Year is already added to this school", flash[:alert]
  end

  test "removing a year takes its quarters and names them" do
    school_year = SchoolYear.create!(school: @school, year: @year)

    assert_difference("Quarter.count", -4) do
      delete admin_school_school_year_path(@school, school_year)
    end

    assert_redirected_to admin_school_path(@school)
    assert_equal "2100 - 2101 removed, along with its 4 quarters.", flash[:notice]
    assert_not SchoolYear.exists?(school_year.id)
  end

  # **The crash.** Through the old form this raised `ActiveRecord::InvalidForeignKey`; here it is refused
  # with a sentence naming the number of classrooms, which is the thing an admin has to go and deal with.
  test "a year with classrooms is refused, not crashed" do
    school_year = SchoolYear.create!(school: @school, year: @year)
    create(:classroom, school_year:, name: "Sixth grade")

    assert_no_difference(["SchoolYear.count", "Quarter.count"]) do
      delete admin_school_school_year_path(@school, school_year)
    end

    assert_redirected_to admin_school_path(@school)
    assert_equal "2100 - 2101 still has 1 classroom, so it cannot be removed.", flash[:alert]
  end

  test "a year belonging to another school cannot be removed through this one" do
    other = create(:school)
    school_year = SchoolYear.create!(school: other, year: @year)

    delete admin_school_school_year_path(@school, school_year)

    # Scoped through `@school.school_years`, so the lookup simply does not find it. The outcome is what
    # matters rather than which exception the environment turns that into.
    assert_response :not_found
    assert SchoolYear.exists?(school_year.id), "another school's year was removed through this one"
  end

  test "a teacher cannot add or remove" do
    school_year = SchoolYear.create!(school: @school, year: @year)
    sign_in create(:teacher)

    post admin_school_school_years_path(@school), params: { year_id: create(:year, name: "2200 - 2201").id }
    delete admin_school_school_year_path(@school, school_year)

    assert_equal 1, @school.reload.school_years.count
  end
end
