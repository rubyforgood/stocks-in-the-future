# frozen_string_literal: true

require "application_system_test_case"

class UserManagesClassroomsTest < ApplicationSystemTestCase
  test "admin can create a new classroom" do
    school1 = create(:school, name: "Elementary School")
    create(:school, name: "High School")
    year1 = create(:year, name: "2023-2024")
    create(:year, name: "2024-2025")
    create(:grade, level: 5, name: "5th Grade")
    admin = create(:admin)
    sign_in(admin)
    visit new_classroom_path

    fill_in "Name", with: "Test Classroom"
    check "5th Grade"
    select school1.name, from: "classroom_school_id"
    select year1.name, from: "classroom_year_id"
    click_on "Create Classroom"

    assert_selector "#notice", text: "Classroom was successfully created"
    assert_selector "h1", text: "Test Classroom"
    assert_selector "h1", text: "2023-2024"
  end

  test "admin can update a classroom" do
    school1 = create(:school, name: "Original School")
    school2 = create(:school, name: "New School")
    year1 = create(:year, name: "2023-2024")
    year2 = create(:year, name: "2024-2025")
    grade5 = create(:grade, level: 5, name: "5th Grade")
    school_year = create(:school_year, school: school1, year: year1)
    classroom = create(:classroom, name: "Original Name", school_year: school_year, grades: [grade5])
    admin = create(:admin)
    sign_in(admin)
    visit edit_classroom_path(classroom)

    fill_in "Name", with: "Updated Classroom"
    select school2.name, from: "classroom_school_id"
    select year2.name, from: "classroom_year_id"
    click_on "Update Classroom"

    assert_selector "#notice", text: "Classroom was successfully updated"
    assert_selector "h1", text: "Updated Classroom"
    assert_selector "h1", text: "2024-2025"
  end
end
