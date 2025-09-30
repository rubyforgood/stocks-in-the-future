# frozen_string_literal: true

require "test_helper"

class SchoolYearsControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    admin = create(:admin)
    sign_in admin

    get admin_school_years_url

    assert_response :success
  end

  test "new" do
    admin = create(:admin)
    sign_in admin

    get new_admin_school_year_url

    assert_response :success
  end

  test "create" do
    school = create(:school)
    year = create(:year)
    params = { school_year: { school_id: school.id, year_id: year.id } }
    admin = create(:admin)
    sign_in admin

    assert_difference(-> { SchoolYear.count } => 1, -> { Quarter.count } => 4) do
      post(admin_school_years_url, params:)
    end

    assert_redirected_to admin_school_year_url(SchoolYear.last)
  end

  test "show" do
    school_year = create(:school_year)
    admin = create(:admin)
    sign_in admin

    get admin_school_year_url(school_year)

    assert_response :success
  end

  test "edit" do
    school_year = create(:school_year)
    admin = create(:admin)
    sign_in admin

    get edit_admin_school_year_url(school_year)

    assert_response :success
  end

  test "update" do
    school1 = create(:school)
    school2 = create(:school)
    year1 = create(:year)
    year2 = create(:year)
    params = { school_year: { school_id: school2.id, year_id: year2.id } }
    school_year = create(:school_year, school: school1, year: year1)
    admin = create(:admin)
    sign_in admin

    patch(admin_school_year_url(school_year), params:)

    assert_redirected_to admin_school_year_url(school_year)
    school_year.reload
    assert_equal(school2.id, school_year.school_id)
    assert_equal(year2.id, school_year.year_id)
  end

  test "destroy" do
    school_year = create(:school_year)
    admin = create(:admin)
    sign_in admin

    assert_difference("SchoolYear.count", -1) do
      delete admin_school_year_url(school_year)
    end

    assert_redirected_to admin_school_years_url
  end
end
