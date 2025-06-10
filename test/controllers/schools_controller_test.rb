# frozen_string_literal: true

require 'test_helper'

class SchoolsControllerTest < ActionDispatch::IntegrationTest
  test 'index' do
    admin = create(:admin)
    sign_in admin

    get schools_url

    assert_response :success
  end

  test 'new' do
    admin = create(:admin)
    sign_in admin

    get new_school_url

    assert_response :success
  end

  test 'create' do
    params = { school: { name: '' } }
    admin = create(:admin)
    sign_in admin

    assert_difference('School.count') do
      post(schools_url, params:)
    end

    assert_redirected_to school_url(School.last)
  end

  test 'show' do
    school = create(:school)
    admin = create(:admin)
    sign_in admin

    get school_url(school)

    assert_response :success
  end

  test 'edit' do
    school = create(:school)
    admin = create(:admin)
    sign_in admin

    get edit_school_url(school)

    assert_response :success
  end

  test 'update' do
    params = { school: { name: 'Abc123' } }
    school = create(:school)
    admin = create(:admin)
    sign_in admin

    assert_changes 'school.reload.updated_at' do
      patch school_url(school), params:
    end

    assert_redirected_to school_url(school)
  end

  test 'destroy' do
    school = create(:school)
    admin = create(:admin)
    sign_in admin

    assert_difference('School.count', -1) do
      delete school_url(school)
    end

    assert_redirected_to schools_url
  end
end
