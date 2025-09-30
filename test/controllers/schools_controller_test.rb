# frozen_string_literal: true

require "test_helper"

class SchoolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @school = create(:school)
    @admin_user = create(:admin)
    sign_in @admin_user
  end

  test "should get index" do
    get admin_schools_url
    assert_response :success
    assert_select "title", /Schools/i
  end

  test "should get new" do
    get new_admin_school_url
    assert_response :success
    assert_select "form"
  end

  test "should create school" do
    assert_difference("School.count") do
      post admin_schools_url, params: { school: { name: "New Test School" } }
    end
    assert_redirected_to admin_school_url(School.last)
    assert_equal "New Test School", School.last.name
  end

  test "should show school" do
    get admin_school_url(@school)
    assert_response :success
    assert_select "h1", /School/
  end

  test "should get edit" do
    get edit_admin_school_url(@school)
    assert_response :success
    assert_select "form"
  end

  test "should update school" do
    patch admin_school_url(@school), params: { school: { name: "Updated School Name" } }
    assert_redirected_to admin_school_url(@school)
    @school.reload
    assert_equal "Updated School Name", @school.name
  end

  test "should destroy school" do
    assert_difference("School.count", -1) do
      delete admin_school_url(@school)
    end
    assert_redirected_to admin_schools_url
  end

  test "requires authentication" do
    sign_out @admin_user
    get admin_schools_url
    assert_redirected_to root_url
  end
end
