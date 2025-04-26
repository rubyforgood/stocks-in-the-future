require "test_helper"

class SchoolsControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    sign_in users(:one)

    get schools_path

    assert_response :success
  end

  test "new" do
    sign_in users(:one)

    get new_school_path

    assert_response :success
  end

  test "create" do
    params = {school: {name: "New School"}}
    sign_in users(:one)

    assert_difference "School.count" do
      post schools_path, params:
    end

    assert_redirected_to school_url(School.last)
  end

  # TODO: test a failed create

  test "show" do
    sign_in users(:one)

    get school_path(schools(:armistead_elementary))

    assert_response :success
  end

  test "edit" do
    sign_in users(:one)

    get edit_school_path(schools(:armistead_elementary))

    assert_response :success
  end

  test "update" do
    school = schools(:armistead_elementary)
    params = {school: {name: "Updated School"}}
    sign_in users(:one)

    assert_changes -> { school.updated_at } do
      patch(school_path(school), params:)
      school.reload
    end

    assert_redirected_to school_url(school)
  end

  # TODO: test a failed update

  # TODO: need to figure out if we want a cascading dependent destroy on all referenced objects
  # school -> classroom -> user -> order
  # test "should destroy school" do
  #   assert_difference("School.count", -1) do
  #     delete school_url(@school)
  #   end

  #   assert_redirected_to schools_url
  # end
end
