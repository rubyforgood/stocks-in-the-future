require "application_system_test_case"

class UserManagesClassroomsTest < ApplicationSystemTestCase
  # TODO: Add test for creating a new classroom
  # TODO: Add test for updating a classroom

  test "should destroy Classroom" do
    classroom = create(:classroom)
    admin = create(:admin)
    sign_in(admin)
    visit classroom_path(classroom)

    click_on "Destroy this classroom"

    assert_text "Classroom was successfully destroyed"
  end
end
