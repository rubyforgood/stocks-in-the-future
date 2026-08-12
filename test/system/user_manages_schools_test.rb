# frozen_string_literal: true

require "application_system_test_case"

class UserManagesSchoolsTest < ApplicationSystemTestCase
  test "admin can create a school" do
    admin = create(:admin)
    sign_in(admin)
    visit admin_schools_path

    click_on "New school"
    fill_in "Name", with: "Test School"
    click_on "Create school"

    assert_selector "#notice", text: "School created successfully"
  end

  test "admin can update a school" do
    school = create(:school, name: "Original School")
    admin = create(:admin)
    sign_in(admin)
    visit admin_school_url(school)

    # No "Edit" step. The record's page edits in place, which is what a detail page does in Stripe,
    # Linear, Shopify admin and Polaris - a separate edit screen for a record with one attribute is a Rails
    # scaffold convention. This test is the clearest statement of what the merged shape changes: a flow that
    # was navigate-then-edit is now just edit.
    fill_in "Name", with: "Updated School"
    click_on "Save details"

    assert_selector "#notice", text: "School updated successfully"
  end

  test "admin can delete a school" do
    school = create(:school, name: "School To Delete")
    admin = create(:admin)
    sign_in(admin)
    visit admin_school_url(school)

    accept_confirmation do
      click_on "Delete"
    end

    assert_selector "#notice", text: "School deleted successfully"
  end
end
