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
    click_on "Save Grades"

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

    assert_button "Finalize Grades"
    accept_confirm do
      click_on "Finalize Grades"
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
    click_on "Save Grades"

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
    click_on "Save Grades"

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
      find("[data-testid='perfect-attendance-checkbox']").check
    end
    click_on "Save Grades"

    within("##{dom_id(student_entry)}") do
      assert find("[data-testid='perfect-attendance-checkbox']").checked?
    end
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
    assert_no_text "Finalize Grades"
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
    assert_selector "input[type='checkbox'][disabled]", count: 2
    assert_no_button "Save Grades"
  end
end
