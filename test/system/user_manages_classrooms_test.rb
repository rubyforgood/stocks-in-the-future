# frozen_string_literal: true

require "application_system_test_case"

class UserManagesClassroomsTest < ApplicationSystemTestCase
  test "admin can create a new classroom using dropdowns" do
    school1 = create(:school, name: "Elementary School")
    school2 = create(:school, name: "High School")
    year1 = create(:year, name: "2023-2024")
    year2 = create(:year, name: "2024-2025")
    admin = create(:admin)
    
    sign_in(admin)
    visit new_classroom_path
    
    # Verify dropdowns are present
    assert_selector "select[name='classroom[school_id]']"
    assert_selector "select[name='classroom[year_id]']"
    
    # Fill out the form
    fill_in "Name", with: "Test Classroom"
    fill_in "Grade", with: "5th"
    select school1.name, from: "classroom_school_id"
    select year1.name, from: "classroom_year_id"
    
    click_on "Create Classroom"
    
    assert_text "Classroom was successfully created"
    classroom = Classroom.last
    assert_equal school1, classroom.school
    assert_equal year1, classroom.year
  end

  test "admin can update a classroom using dropdowns" do
    school1 = create(:school, name: "Original School")
    school2 = create(:school, name: "New School")
    year1 = create(:year, name: "2023-2024")
    year2 = create(:year, name: "2024-2025")
    
    school_year = create(:school_year, school: school1, year: year1)
    classroom = create(:classroom, name: "Original Name", school_year: school_year)
    admin = create(:admin)
    
    sign_in(admin)
    visit edit_classroom_path(classroom)
    
    # Verify current values are selected
    assert_selector "select[name='classroom[school_id]'] option[selected]", text: school1.name
    assert_selector "select[name='classroom[year_id]'] option[selected]", text: year1.name
    
    # Update the form
    fill_in "Name", with: "Updated Classroom"
    select school2.name, from: "classroom_school_id"
    select year2.name, from: "classroom_year_id"
    
    click_on "Update Classroom"
    
    assert_text "Classroom was successfully updated"
    classroom.reload
    assert_equal "Updated Classroom", classroom.name
    assert_equal school2, classroom.school
    assert_equal year2, classroom.year
  end

  test "should destroy Classroom" do
    classroom = create(:classroom)
    admin = create(:admin)
    sign_in(admin)
    visit classroom_path(classroom)

    click_on "Destroy this classroom"

    assert_text "Classroom was successfully destroyed"
  end
end
