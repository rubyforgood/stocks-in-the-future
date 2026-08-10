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

    click_on "Add student"
    fill_in "Full name", with: "Jordan Smith"
    fill_in "Username", with: username
    click_button "Create student"

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
    username = "student_one"
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom:, username:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_path(classroom)

    assert_selector "##{dom_id(student)} [data-testid='reset-password']"
    accept_confirmation do
      find("##{dom_id(student)} [data-testid='reset-password']").click
    end

    # Three things in here were stale rather than flaky, which is why this was skipped as "flaky" and
    # never looked at again:
    #
    #   - `p#notice` - the flash is a `<div id="notice">` and has been since it gained its icon and
    #     `role="status"`;
    #   - `fill_in "Full name"` on the **sign-in** page, which only asks for a username and a password;
    #   - an h1 of "WELCOME TO YOUR FINANCIAL JOURNEY!", which the sentence-case sweep retitled.
    #
    # None of those is a race. A test skipped as flaky is a test nobody reads the failure of.
    assert_selector "#notice", text: "Password reset for #{username}"
    new_password = find("#notice").text.match(/New password: (\S+)/)[1]

    # Through the UI, not `sign_out`: switching users is the one thing Warden's test-mode helpers
    # cannot do reliably here. See ApplicationSystemTestCase#sign_out_through_the_ui.
    sign_out_through_the_ui

    fill_in "Username", with: username
    fill_in "Password", with: new_password
    click_button "Sign in"

    # The password the teacher was shown is the password that works - which is the whole point of the
    # reset, and the assertion the skip was hiding. Assert that we are signed in **as this student**,
    # not that we landed on a particular page.
    #
    # This used to assert the home page's h1, and that couples the test to Devise's post-sign-in
    # destination: `after_sign_in_path_for` honours a stored location, so when one had been recorded
    # the student landed on their portfolio instead and the test failed while the password worked
    # perfectly. The account menu names the signed-in user and renders on every signed-in page, so it
    # asserts the claim this test actually makes.
    assert_selector "[data-testid='account-menu']", text: student.display_name
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
    click_button "Update student"

    assert_selector "#notice", text: "Student updated successfully"
    assert_selector "[data-testid='student-username']", text: new_username
    assert_no_selector "[data-testid='student-username']", text: old_username
  end

  test "teacher can delete a student" do
    username = "student_one"
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom:, username:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_path(classroom)

    assert_selector "##{dom_id(student)} [data-testid='delete-student']"
    accept_confirmation do
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

    click_on "Add student"
    fill_in "Full name", with: "Jordan Smith"
    fill_in "Username", with: username
    click_button "Create student"

    assert_selector ".field_with_errors", text: "Username"
  end
end
