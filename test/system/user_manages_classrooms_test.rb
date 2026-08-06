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
    click_on "Create classroom"

    assert_selector "#notice", text: "Classroom was successfully created"
    assert_selector "h1", text: "Test Classroom"
    assert_selector "p", text: "2023-2024"
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
    click_on "Update classroom"

    assert_selector "#notice", text: "Classroom was successfully updated"
    assert_selector "h1", text: "Updated Classroom"
    assert_selector "p", text: "2024-2025"
  end

  # A teacher edits the classroom they teach, end to end from the list.
  test "teacher can rename the classroom they teach" do
    classroom = create(:classroom, name: "Original Name", grades: [create(:grade, level: 5, name: "5th Grade")])
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)

    visit classrooms_path
    click_on "Edit"

    fill_in "Name", with: "Renamed By Teacher"
    click_on "Update classroom"

    assert_selector "#notice", text: "Classroom was successfully updated"
    assert_selector "h1", text: "Renamed By Teacher"
  end

  # The fields a teacher may not change are not on their form at all. Rendering them would invite a
  # teacher to fill in a school or a teacher list whose values the parameter filter then drops - the
  # page would look like it saved and quietly would not.
  test "a teacher's edit form offers only what a teacher may change" do
    classroom = create(:classroom, grades: [create(:grade, level: 5, name: "5th Grade")])
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)

    visit edit_classroom_path(classroom)

    assert_selector "input#classroom_name"
    assert_selector "input[name='classroom[grade_ids][]']", visible: :all
    assert_no_selector "select#classroom_school_id"
    assert_no_selector "select#classroom_year_id"
    assert_no_selector "input[name='classroom[teacher_ids][]']", visible: :all
  end

  test "an admin's edit form still offers all of them" do
    classroom = create(:classroom, grades: [create(:grade, level: 5, name: "5th Grade")])
    sign_in(create(:admin))

    visit edit_classroom_path(classroom)

    assert_selector "select#classroom_school_id"
    assert_selector "select#classroom_year_id"
    assert_selector "input[name='classroom[teacher_ids][]']", visible: :all
  end

  test "admin can update trading for a classroom" do
    classroom = create(:classroom, trading_enabled: false)
    admin = create(:admin)
    sign_in(admin)
    visit classroom_path(classroom)

    check "trading", allow_label_click: true
    assert_selector "#notice", text: "Trading has been enabled for this classroom."
    uncheck "trading", allow_label_click: true
    assert_selector "#notice", text: "Trading has been disabled for this classroom."
  end
end
