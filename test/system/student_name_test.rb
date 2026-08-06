# frozen_string_literal: true

require "application_system_test_case"

# Students have a name now, and it is what appears.
#
# `users.name` existed the whole time and `User#display_name` has always preferred it, but nothing
# collected it - `students#new` took a username and nothing else - so every student's name was nil and
# every screen fell back to the lowercased identifier they sign in with. Reported as "why are all the
# student names lowercase". They were not names, and capitalising them would have been wrong: usernames
# are downcased because sign-in is case-insensitive, so `jsmith2` would have rendered as `Jsmith2`.
class StudentNameTest < ApplicationSystemTestCase
  def teacher_in(classroom)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    teacher
  end

  test "a teacher can give a new student a name" do
    classroom = create(:classroom, :with_trading)
    sign_in teacher_in(classroom)

    visit new_classroom_student_path(classroom)
    fill_in "Full name", with: "Jordan Smith"
    fill_in "Username", with: "jsmith2"
    click_on "Create student"
    # Wait for the response before querying: click_on does not block, so a bare find_by races the POST.
    assert_selector "#notice"

    student = Student.find_by(username: "jsmith2")

    assert_equal "Jordan Smith", student.name
    assert_equal "Jordan Smith", student.display_name
  end

  # Optional, because every existing student has none and requiring it would block editing them.
  test "the name is optional" do
    classroom = create(:classroom, :with_trading)
    sign_in teacher_in(classroom)

    visit new_classroom_student_path(classroom)
    fill_in "Username", with: "nameless"
    click_on "Create student"
    assert_selector "#notice"

    student = Student.find_by(username: "nameless")

    assert_nil student.name
    assert_equal "nameless", student.display_name, "display_name must fall back to the username"
  end

  test "a teacher can add a name to an existing student" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, classroom:, username: "existing")
    sign_in teacher_in(classroom)

    visit edit_classroom_student_path(classroom, student)
    fill_in "Full name", with: "Ada Lovelace"
    click_on "Update student"
    assert_selector "#notice"

    assert_equal "Ada Lovelace", student.reload.name
  end

  # The roster shows the name as the primary line with the username beneath it - design.md's
  # primary-identifier shape, and what GitHub does for a person. Both are needed: the name is who the
  # teacher is looking for, the username is what a password reset refers to.
  test "the roster shows the name over the username" do
    classroom = create(:classroom, :with_trading)
    create(:student, :with_portfolio, classroom:, username: "jsmith2", name: "Jordan Smith")
    sign_in teacher_in(classroom)

    visit classroom_path(classroom)

    within("[data-testid='student-username']", match: :first) do
      assert_selector "a", text: "Jordan Smith"
      assert_text "jsmith2"
    end
  end

  # A student with no name shows one line, not the same string twice.
  test "the roster shows a nameless student once" do
    classroom = create(:classroom, :with_trading)
    create(:student, :with_portfolio, classroom:, username: "nameless")
    sign_in teacher_in(classroom)

    visit classroom_path(classroom)

    cell = find("[data-testid='student-username']", match: :first)

    occurrences = cell.text.lines.count { |line| line.strip == "nameless" }

    assert_equal 1, occurrences
  end

  test "the grade book and the portfolio use the name" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:, username: "jsmith2", name: "Jordan Smith")
    student.reload
    book = classroom.grade_books.first
    create(:grade_entry, grade_book: book, user: student)
    sign_in teacher_in(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_text "Jordan Smith"

    visit user_portfolio_path(student, student.portfolio)

    assert_selector "h1", text: "Jordan Smith's portfolio"
  end

  test "an admin can set a student's name too" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, classroom:, username: "adminedit")
    sign_in create(:admin)

    visit edit_admin_student_path(student)
    fill_in "Full name", with: "Grace Hopper"
    click_on "Update student"
    assert_selector "#notice"

    assert_equal "Grace Hopper", student.reload.name
  end
end
