require "test_helper"

class SchoolsControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    user = create(:user)
    sign_in user

    get schools_url

    assert_response :success
  end

  test "new" do
    user = create(:user)
    sign_in user

    get new_school_url

    assert_response :success
  end

  test "create" do
    params = {school: {name: ""}}
    user = create(:user)
    sign_in user

    assert_difference("School.count") do
      post(schools_url, params:)
    end

    assert_redirected_to school_url(School.last)
  end

  test "show" do
    school = create(:school)
    user = create(:user)
    sign_in user

    get school_url(school)

    assert_response :success
  end

  test "edit" do
    school = create(:school)
    user = create(:user)
    sign_in user

    get edit_school_url(school)

    assert_response :success
  end

  test "update" do
    params = {school: {name: "Abc123"}}
    school = create(:school)
    user = create(:user)
    sign_in user

    assert_changes "school.reload.updated_at" do
      patch school_url(school), params:
    end

    assert_redirected_to school_url(school)
  end

  test "destroy" do
    school = create(:school)
    user = create(:user)
    sign_in user

    assert_difference("School.count", -1) do
      delete school_url(school)
    end

    assert_redirected_to schools_url
  end
end
