# frozen_string_literal: true

require "application_system_test_case"

# One classroom form, rendered at two URLs.
#
# /classrooms/new and /admin/classrooms/new were two different forms for one model, and they had drifted
# into two different products: the app one asks for a school and a year and offers the teacher
# assignment, the admin one asked for a single school year, offered no teachers, and led with an `h3`
# restating the page title. An admin got different fields depending which URL they came in through.
#
# These tests click the real form, which is the only assertion that cannot agree with a broken
# controller: the admin controller permitted `school_year_id`, its own hand-written list, while the
# form posts `school_id` and `year_id` - and every controller test passed, because they hand-wrote the
# same params the controller expected.
class ClassroomFormConsistencyTest < ApplicationSystemTestCase
  FIELDS = <<~JS
    (function () {
      const form = document.querySelector("main form");
      return [...form.querySelectorAll("label, legend")]
        .map(function (l) { return l.textContent.replace(/\\s+/g, " ").trim(); })
        .filter(function (t) { return t.length && t.length < 40; });
    })()
  JS

  test "both halves render the same fields, in the same order" do
    create(:school, name: "Oak Primary")
    create(:year, name: "2026")
    create(:grade, level: 5, name: "5th Grade")
    create(:teacher, name: "Terry Teacher")
    sign_in create(:admin)

    visit new_classroom_path
    app_fields = page.evaluate_script(FIELDS)

    visit new_admin_classroom_path
    admin_fields = page.evaluate_script(FIELDS)

    assert_equal app_fields, admin_fields,
                 "the two classroom forms have diverged again - they render one partial"
    assert_includes app_fields.join(" "), "Teachers"
  end

  test "an admin creates a classroom through the admin form" do
    school = create(:school, name: "Oak Primary")
    year = create(:year, name: "2026")
    create(:grade, level: 5, name: "5th Grade")
    sign_in create(:admin)

    visit new_admin_classroom_path
    fill_in "Name", with: "5B"
    select "Oak Primary", from: "School name"
    select "2026", from: "Year"
    check "5th Grade"

    assert_difference("Classroom.count", 1) do
      click_on "Create classroom"
      assert_text "5B"
    end

    classroom = Classroom.last

    assert_equal "5B", classroom.name
    # The pair is found-or-created rather than picked from a list, so an admin does not have to make a
    # SchoolYear row before they can make a classroom in a year nobody has used yet.
    assert_equal school, classroom.school_year.school
    assert_equal year, classroom.school_year.year
  end

  test "an admin can assign a teacher from the admin form, which it could not do before" do
    create(:school)
    create(:year)
    create(:grade, level: 5, name: "5th Grade")
    teacher = create(:teacher, name: "Terry Teacher")
    sign_in create(:admin)

    visit new_admin_classroom_path
    fill_in "Name", with: "5C"
    select School.first.name, from: "School name"
    select Year.first.name, from: "Year"
    check "5th Grade"
    check teacher.display_name
    click_on "Create classroom"

    assert_text "5C"
    # ADMIN_ATTRIBUTES has always permitted teacher_ids; the admin controller's own hand-written list
    # did not, so the half of the product whose job is administration was the half that could not do this.
    assert_includes Classroom.last.teachers, teacher
  end

  test "an invalid admin submit shows one summary and one message per field" do
    create(:school)
    create(:year)
    create(:grade, level: 5, name: "5th Grade")
    sign_in create(:admin)

    visit new_admin_classroom_path
    page.execute_script("document.querySelector('main form').setAttribute('novalidate', '')")
    click_on "Create classroom"

    assert_selector "[data-testid=form-errors]", text: "stopped this classroom being saved"

    # One message per field, not two. Admin fields used to carry the form builder's own "can't be blank"
    # *and* the field_error_proc's "Name can't be blank", in different colours, each with its own icon.
    assert_equal 1, page.all("p", text: "Name can't be blank").count
    assert_no_text "can’t be blank\ncan't be blank"
  end

  test "an invalid submit on the app half looks identical" do
    create(:school)
    create(:year)
    create(:grade, level: 5, name: "5th Grade")
    sign_in create(:admin)

    visit new_classroom_path
    page.execute_script("document.querySelector('main form').setAttribute('novalidate', '')")
    click_on "Create classroom"

    assert_selector "[data-testid=form-errors]", text: "stopped this classroom being saved"
    assert_equal 1, page.all("p", text: "Name can't be blank").count
  end
end
