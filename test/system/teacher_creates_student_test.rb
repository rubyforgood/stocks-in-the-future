# frozen_string_literal: true

require "application_system_test_case"

class TeacherCreatesStudentTest < ApplicationSystemTestCase
  test "teacher creates student successfully" do
    teacher = create(:teacher)
    classroom = create(:classroom)
    TeacherClassroom.create(teacher: teacher, classroom: classroom)

    sign_in(teacher)

    visit classroom_path(classroom)

    click_on "Add Student"

    assert_text "Add New Student"

    fill_in "Username", with: "john_doe"

    assert_difference("Student.count", 1) do
      click_button "Create Student"

      assert_text "Student john_doe created successfully"
    end

    student = Student.find_by(username: "john_doe")
    assert student.present?, "Student should exist in database"
    assert student.classroom == classroom, "Student should be associated with the classroom"
    assert student.portfolio.present?, "Student should have a portfolio auto-created"

    assert_text "john_doe"

    sign_out(teacher)
  end

  test "teacher views student list" do
    teacher = create(:teacher)
    classroom = create(:classroom)
    TeacherClassroom.create(teacher: teacher, classroom: classroom)

    alice = create(:student, :with_portfolio, classroom: classroom, username: "alice_smith")
    bob = create(:student, :with_portfolio, classroom: classroom, username: "bob_jones")
    carol = create(:student, :with_portfolio, classroom: classroom, username: "carol_davis")

    sign_in(teacher)

    visit classroom_path(classroom)

    assert_text alice.username
    assert_text bob.username
    assert_text carol.username

    assert_selector "i.fa-pencil", count: 3 # Edit buttons
    assert_selector "i.fa-trash", count: 3 # Delete buttons

    sign_out(teacher)
  end

  test "teacher resets student password" do
    teacher = create(:teacher)
    classroom = create(:classroom)
    TeacherClassroom.create(teacher: teacher, classroom: classroom)

    old_password = "OldPass123"
    jane = create(:student, :with_portfolio, classroom: classroom, username: "jane_smith", password: old_password)

    sign_in(teacher)

    visit classroom_path(classroom)

    auto_accept_confirmations
    within "tr", text: jane.username do
      find("a[title='Reset password']").click
    end

    assert_text "Password reset for jane_smith"

    notice_text = find("p#notice").text
    new_password = notice_text.match(/New password: (.+)/)[1]

    assert new_password.present?, "New password should be displayed"
    assert new_password != old_password, "New password should be different from old password"

    sign_out(teacher)

    # Verify the student can log in with the new password
    visit new_user_session_path
    fill_in "Username", with: jane.username
    fill_in "Password", with: new_password
    click_button "Sign in"

    assert_no_selector "div.alert", text: /invalid/i

    # Verify old password no longer works
    click_on "Logout"

    fill_in "Username", with: jane.username
    fill_in "Password", with: old_password
    click_button "Sign in"

    assert_current_path new_user_session_path
  end

  test "teacher edits student information" do
    teacher = create(:teacher)
    classroom = create(:classroom)
    TeacherClassroom.create(teacher: teacher, classroom: classroom)

    student = create(:student, classroom: classroom, username: "bob_jones")
    portfolio = student.portfolio

    sign_in(teacher)

    visit classroom_path(classroom)

    within "tr", text: student.username do
      find("i.fa-pencil").click
    end

    assert_text "Edit Student"

    fill_in "Username", with: "robert_jones"

    click_button "Update Student"

    assert_text "Student updated successfully"

    student.reload
    assert_equal "robert_jones", student.username, "Username should be updated"
    assert_equal classroom, student.classroom, "Classroom should remain unchanged"
    assert_equal portfolio.id, student.portfolio.id, "Portfolio should remain intact (same ID)"

    assert_text "robert_jones"
    assert_no_text "bob_jones"

    sign_out(teacher)
  end

  test "teacher soft deletes student" do
    teacher = create(:teacher)
    classroom = create(:classroom)
    TeacherClassroom.create(teacher: teacher, classroom: classroom)

    student = create(:student, :with_portfolio, classroom: classroom, username: "alice_wong")
    portfolio = student.portfolio

    sign_in(teacher)

    visit classroom_path(classroom)

    assert_text "alice_wong"

    assert_no_difference("Student.count") do
      auto_accept_confirmations

      within "tr", text: "alice_wong" do
        find("i.fa-trash").click
      end

      assert_text "Student alice_wong deleted successfully"
    end

    within "tbody" do
      assert_no_text "alice_wong"
    end

    student.reload
    assert student.discarded?, "Student should be discarded (soft deleted)"

    assert portfolio.reload.present?, "Student's portfolio should still exist"

    sign_out(teacher)
  end

  test "teacher cannot create student with duplicate username" do
    teacher = create(:teacher)
    classroom = create(:classroom)
    TeacherClassroom.create(teacher: teacher, classroom: classroom)

    create(:student, classroom: classroom, username: "existing_user")

    sign_in(teacher)

    visit classroom_path(classroom)
    click_on "Add Student"

    fill_in "Username", with: "existing_user"

    assert_no_difference("Student.count") do
      click_button "Create Student"

      assert_text "Username has already been taken"
    end

    assert_text "Add New Student"

    sign_out(teacher)
  end
end
