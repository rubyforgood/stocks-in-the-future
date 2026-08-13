# frozen_string_literal: true

require "application_system_test_case"

class GradeBooksTest < ApplicationSystemTestCase
  test "teacher updates grade book entries" do
    classroom = create(:classroom)
    grade_book = create(:grade_book, classroom:)
    student1 = create(:student, classroom:)
    student2 = create(:student, classroom:)
    student1_entry = create(:grade_entry, grade_book:, user: student1)
    student2_entry = create(:grade_entry, grade_book:, user: student2)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_grade_book_path(classroom, grade_book)

    within("##{dom_id(student1_entry)}") do
      find("[data-testid='math-grade-select']").select("A")
      find("[data-testid='reading-grade-select']").select("B+")
      find("[data-testid='attendance-days-input']").set(95)
    end
    within("##{dom_id(student2_entry)}") do
      find("[data-testid='math-grade-select']").select("B")
      find("[data-testid='reading-grade-select']").select("A")
      find("[data-testid='attendance-days-input']").set(87)
    end
    click_on "Save grades"

    within("##{dom_id(student1_entry)}") do
      assert_equal "A", find("[data-testid='math-grade-select']").value
      assert_equal "B+", find("[data-testid='reading-grade-select']").value
      assert_equal "95", find("[data-testid='attendance-days-input']").value
    end
    within("##{dom_id(student2_entry)}") do
      assert_equal "B", find("[data-testid='math-grade-select']").value
      assert_equal "A", find("[data-testid='reading-grade-select']").value
      assert_equal "87", find("[data-testid='attendance-days-input']").value
    end
  end
  test "admin sees success message when finalizing grade book" do
    DistributeEarnings.stubs(:execute)
    classroom = create(:classroom)
    grade_book = create(:grade_book, classroom:)
    student1 = create(:student, classroom:)
    student2 = create(:student, classroom:)
    create(:grade_entry, grade_book:, user: student1)
    create(:grade_entry, grade_book:, user: student2)
    admin = create(:admin)
    sign_in(admin)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_button "Finalize grades"
    accept_confirmation do
      click_on "Finalize grades"
    end

    assert_selector(
      "#notice",
      text: "Grade book finalized. Funds have been distributed."
    )
  end

  test "teacher enters grades for multiple students" do
    classroom = create(:classroom)
    grade_book = create(:grade_book, classroom:)
    student1 = create(:student, classroom:)
    student2 = create(:student, classroom:)
    student1_entry = create(:grade_entry, grade_book:, user: student1)
    student2_entry = create(:grade_entry, grade_book:, user: student2)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_grade_book_path(classroom, grade_book)

    within("##{dom_id(student1_entry)}") do
      find("[data-testid='math-grade-select']").select("A")
      find("[data-testid='reading-grade-select']").select("B+")
      find("[data-testid='attendance-days-input']").set(95)
    end
    within("##{dom_id(student2_entry)}") do
      find("[data-testid='math-grade-select']").select("B")
      find("[data-testid='reading-grade-select']").select("A")
      find("[data-testid='attendance-days-input']").set(87)
    end
    click_on "Save grades"

    within("##{dom_id(student1_entry)}") do
      assert_equal "A", find("[data-testid='math-grade-select']").value
      assert_equal "B+", find("[data-testid='reading-grade-select']").value
    end
    within("##{dom_id(student2_entry)}") do
      assert_equal "B", find("[data-testid='math-grade-select']").value
      assert_equal "A", find("[data-testid='reading-grade-select']").value
    end
  end

  test "teacher updates previously entered grades" do
    classroom = create(:classroom)
    grade_book = create(:grade_book, classroom:)
    student_entry = create(:grade_entry, grade_book:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_grade_book_path(classroom, grade_book)

    within("##{dom_id(student_entry)}") do
      find("[data-testid='math-grade-select']").select("A")
      find("[data-testid='reading-grade-select']").select("B+")
      find("[data-testid='attendance-days-input']").set(25)
    end
    click_on "Save grades"

    within("##{dom_id(student_entry)}") do
      assert_equal "A", find("[data-testid='math-grade-select']").value
      assert_equal "B+", find("[data-testid='reading-grade-select']").value
    end
  end

  test "teacher marks student with perfect attendance" do
    classroom = create(:classroom)
    grade_book = create(:grade_book, classroom:)
    student = create(:student, classroom:)
    student_entry = create(:grade_entry, grade_book:, user: student)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_grade_book_path(classroom, grade_book)

    within("##{dom_id(student_entry)}") do
      find("[data-testid='math-grade-select']").select("A")
      find("[data-testid='reading-grade-select']").select("A")
      find("[data-testid='attendance-days-input']").set(90)
      # A segmented Yes/No now, so the answer is chosen rather than ticked. The radio is sr-only and
      # its label is the visible control, which is how a native segmented control works.
      find("[data-testid='perfect-attendance-control']").find("label", text: "Yes").click
    end
    click_on "Save grades"

    within("##{dom_id(student_entry)}") do
      # The Yes radio is sr-only, so it is asserted rather than looked for visibly.
      assert find("[data-testid='perfect-attendance-control']")
        .find("input[type='radio'][value='true']", visible: :all).checked?
    end

    assert student_entry.reload.is_perfect_attendance
  end

  test "teacher can view but cannot finalize grade book" do
    classroom = create(:classroom)
    grade_book = create(:grade_book, classroom:)
    student1 = create(:student, classroom:)
    student2 = create(:student, classroom:)
    student1_entry = create(:grade_entry, grade_book:, user: student1)
    student2_entry = create(:grade_entry, grade_book:, user: student2)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_selector "##{dom_id(student1_entry)}"
    assert_selector "##{dom_id(student2_entry)}"
    assert_no_text "Finalize grades"
  end

  test "teacher cannot view grade books from other classrooms" do
    classroom = create(:classroom)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    other_classroom = create(:classroom)
    other_grade_book = create(:grade_book, classroom: other_classroom)
    sign_in(teacher)

    visit classroom_grade_book_path(other_classroom, other_grade_book)

    assert_current_path root_path
  end

  test "grade book displays validation for attendance input" do
    classroom = create(:classroom)
    grade_book = create(:grade_book, classroom:)
    student = create(:student, classroom:)
    student_entry = create(:grade_entry, grade_book:, user: student)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)

    visit classroom_grade_book_path(classroom, grade_book)

    within("##{dom_id(student_entry)}") do
      assert_selector "input[type='number'][min='0']"
    end
  end

  test "teacher cannot edit finalized grade book" do
    classroom = create(:classroom)
    grade_book = create(:grade_book, classroom:, status: :completed)
    create(:grade_entry, grade_book:)
    create(:grade_entry, grade_book:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_selector "select[disabled]", count: 4
    assert_selector "input[type='number'][disabled]", count: 2
    # Two radios per row now, not one checkbox: perfect attendance is a segmented Yes/No, because a
    # bare tick said nothing about what was being answered.
    assert_selector "input[type='radio'][disabled]", count: 4, visible: :all
    assert_no_button "Save grades"
  end

  # These two exercise the buttons through a real click rather than posting to the
  # route. The buttons have to sit outside the grades form: nested forms are dropped
  # by the browser, so a button placed inside it would submit the grades instead.
  test "teacher adds the class's students to an empty grade book" do
    classroom = create(:classroom)
    grade_book = create(:grade_book, classroom:)
    create_list(:student, 2, classroom:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_text "No students yet"

    # The section header's control, not one inside the empty state. `can_populate` is computed before the
    # branch, so it renders on an empty grade book exactly when there is somebody to add.
    click_on "Add new students"

    assert_selector "#notice", text: "Added 2 students to this grade book."
    assert_selector "tbody tr", count: 2
  end

  test "teacher adds a student who joined after the grade book was filled" do
    classroom = create(:classroom)
    grade_book = create(:grade_book, classroom:)
    create(:grade_entry, grade_book:, user: create(:student, classroom:))
    create(:student, classroom:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    visit classroom_grade_book_path(classroom, grade_book)

    assert_selector "tbody tr", count: 1

    click_on "Add new students"

    assert_selector "#notice", text: "Added 1 student to this grade book."
    assert_selector "tbody tr", count: 2
  end
end
