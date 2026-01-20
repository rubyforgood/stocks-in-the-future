# frozen_string_literal: true

require "application_system_test_case"

class UserManagesSchoolsTest < ApplicationSystemTestCase
  test "admin can create a school" do
    admin = create(:admin)
    sign_in(admin)
    visit admin_schools_path

    click_on "New school"
    fill_in "Name", with: "Test School"
    click_on "Create School"

    assert_selector ".flash", text: "School was successfully created"
  end

  test "admin can update a school" do
    school = create(:school, name: "Original School")
    admin = create(:admin)
    sign_in(admin)
    visit admin_school_url(school)

    click_on "Edit School"
    fill_in "Name", with: "Updated School"
    click_on "Update School"

    assert_selector ".flash", text: "School was successfully updated"
  end

  test "admin can delete a school" do
    school = create(:school, name: "School To Delete")
    admin = create(:admin)
    sign_in(admin)
    visit admin_school_url(school)

    accept_confirm do
      click_on "Destroy"
    end

    assert_selector ".flash", text: "School was successfully destroyed"
  end
end
