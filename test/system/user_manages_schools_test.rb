# frozen_string_literal: true

require "application_system_test_case"

class UserManagesSchoolsTest < ApplicationSystemTestCase
  test "creating a new school" do
    admin = create(:admin)
    sign_in(admin)
    visit admin_schools_path

    click_on "New school"

    fill_in "Name", with: "Abc123"
    click_on "Create School"

    assert_selector ".flash", text: "School was successfully created"
  end

  test "updating a school" do
    admin = create(:admin)
    sign_in(admin)
    school = create(:school)
    visit admin_school_url(school)

    click_on "Edit School"
    fill_in "Name", with: "Abc123"
    click_on "Update School"

    assert_selector ".flash", text: "School was successfully updated"
  end

  test "deleting a school" do
    admin = create(:admin)
    sign_in(admin)
    school = create(:school)
    visit admin_school_url(school)

    accept_confirm do
      click_on "Destroy"
    end

    assert_selector ".flash", text: "School was successfully destroyed"
  end
end
