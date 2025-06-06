require "application_system_test_case"

class UserManagesSchoolsTest < ApplicationSystemTestCase
  test "creating a new school" do
    admin = create(:admin)
    sign_in(admin)
    visit schools_url

    click_on "New school"

    fill_in "Name", with: "Abc123"
    click_on "Create School"

    assert_text "School was successfully created"
  end

  test "updating a school" do
    admin = create(:admin)
    sign_in(admin)
    school = create(:school)
    visit school_url(school)

    click_on "Edit this school"
    fill_in "Name", with: "Abc123"
    click_on "Update School"

    assert_text "School was successfully updated"
  end

  test "deleting a school" do
    admin = create(:admin)
    sign_in(admin)
    school = create(:school)
    visit school_url(school)

    click_on "Destroy this school"

    assert_text "School was successfully destroyed"
  end
end
