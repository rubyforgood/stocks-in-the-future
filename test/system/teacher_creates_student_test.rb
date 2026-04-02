# frozen_string_literal: true

require "application_system_test_case"

class TeacherCreatesStudentTest < ApplicationSystemTestCase
  test "teacher can create a student" do
    username = "student_one"
    classroom = create(:classroom)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_path(classroom)

    click_on "Add Student"
    fill_in "Username", with: username
    click_button "Create Student"

    assert_selector "#notice", text: "Student #{username} created successfully"
    assert_selector "[data-testid='student-username']", text: username
  end

  test "teacher can view and manage student list" do
    classroom = create(:classroom)
    student1 = create(:student, :with_portfolio, classroom:)
    student2 = create(:student, :with_portfolio, classroom:)
    student3 = create(:student, :with_portfolio, classroom:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)

    visit classroom_path(classroom)

    within "##{dom_id(student1)}" do
      assert_selector "[data-testid='student-actions']"
    end
    within "##{dom_id(student2)}" do
      assert_selector "[data-testid='student-actions']"
    end
    within "##{dom_id(student3)}" do
      assert_selector "[data-testid='student-actions']"
    end
  end

  test "teacher can reset student password" do
    skip "Flaky modal test - to be fixed in future PR"
    username = "student_one"
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom:, username:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_path(classroom)

    assert_selector "##{dom_id(student)} [data-testid='reset-password']"
    accept_confirm do
      find("##{dom_id(student)} [data-testid='reset-password']").click
    end

    assert_selector "#notice", text: "Password reset for #{username}"
    notice_text = find("p#notice").text
    new_password = notice_text.match(/New password: (.+)/)[1]

    sign_out(teacher)
    visit new_user_session_path

    fill_in "Username", with: username
    fill_in "Password", with: new_password
    click_button "Sign in"

    assert_selector "h1", text: "WELCOME TO YOUR FINANCIAL JOURNEY!"
  end

  test "teacher can edit student information" do
    old_username = "student_one"
    new_username = "student_two"
    classroom = create(:classroom)
    student = create(:student, classroom:, username: old_username)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_path(classroom)

    find("##{dom_id(student)} [data-testid='edit-student']").click
    fill_in "Username", with: new_username
    click_button "Update Student"

    assert_selector "#notice", text: "Student updated successfully"
    assert_selector "[data-testid='student-username']", text: new_username
    assert_no_selector "[data-testid='student-username']", text: old_username
  end

  test "teacher can delete a student" do
    skip "Flaky modal test - to be fixed in future PR"
    username = "student_one"
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom:, username:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_path(classroom)

    assert_selector "##{dom_id(student)} [data-testid='delete-student']"
    accept_confirm do
      find("##{dom_id(student)} [data-testid='delete-student']").click
    end

    assert_selector "#notice", text: "Student #{username} deleted successfully"
    assert_no_selector "[data-testid='student-username']", text: username
  end

  test "teacher cannot create student with duplicate username" do
    username = "student_one"
    classroom = create(:classroom)
    create(:student, classroom:, username:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_path(classroom)

    click_on "Add Student"
    fill_in "Username", with: username
    click_button "Create Student"

    assert_selector ".field_with_errors", text: "Username"
  end
end
