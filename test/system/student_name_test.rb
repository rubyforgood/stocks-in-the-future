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

  # Required where a human is typing. A roster of lowercased usernames is guesswork - `jsmith2` and
  # `jsmith3` are indistinguishable - so the form will not create a student without a name.
  test "the form will not create a student without a name" do
    classroom = create(:classroom, :with_trading)
    sign_in teacher_in(classroom)

    visit new_classroom_student_path(classroom)

    assert_selector "input#student_name[required]"

    # Past the browser's own check, to prove the server refuses it too - a required attribute is not a
    # validation.
    page.execute_script("document.querySelector('#student_name').removeAttribute('required')")
    fill_in "Username", with: "noname"
    click_on "Create student"

    assert_nil Student.find_by(username: "noname"), "the server accepted a student with no name"
    assert_text "Name can't be blank"
  end

  # And *not* required on import, which is the other half of the same decision: ImportStudentService takes
  # a username and a classroom id from a CSV, so a model-wide requirement would fail every row of a class
  # being onboarded. The column is offered, not demanded.
  test "an import may omit the name, and may carry one" do
    classroom = create(:classroom, :with_trading)

    with_name = ImportStudentService.call(
      username: "imported1", classroom_id: classroom.id, name: "Ada Lovelace"
    )
    without = ImportStudentService.call(username: "imported2", classroom_id: classroom.id)

    assert_predicate with_name, :success?
    assert_predicate without, :success?
    assert_equal "Ada Lovelace", Student.find_by(username: "imported1").name
    assert_nil Student.find_by(username: "imported2").name
    assert_equal "imported2", Student.find_by(username: "imported2").display_name
  end

  # A student who predates the requirement can still be edited - the rule is a form-context validation,
  # not a blanket presence check, so a password reset on a nameless student does not start failing on a
  # field nobody touched.
  test "a teacher can add a name to a student that has none" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :nameless, classroom:, username: "existing")
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
