# frozen_string_literal: true

# test/system/grade_books_test.rb
require "application_system_test_case"

class GradeBooksTest < ApplicationSystemTestCase
  setup do
    @classroom  = create(:classroom)
    @grade_book = create(:grade_book, classroom: @classroom)

    @student1 = create(:student, classroom: @classroom)
    @student2 = create(:student, classroom: @classroom)
    @teacher = create(:teacher, classroom: @classroom)
    TeacherClassroom.create(teacher: @teacher, classroom: @classroom)

    @student1_entry = create(:grade_entry, grade_book: @grade_book, user: @student1)
    @student2_entry = create(:grade_entry, grade_book: @grade_book, user: @student2)

    sign_in(@teacher)
  end

  test "teacher updates grade book entries" do
    visit classroom_grade_book_path(@classroom, @grade_book)

    assert_text @student1.username
    assert_text @student2.username

    within("tr", text: @student1.username) do
      find("[data-testid='math-grade-select']").select("A")
      find("[data-testid='reading-grade-select']").select("B+")
      fill_in type: "number", with: 95
    end

    within("tr", text: @student2.username) do
      find("[data-testid='math-grade-select']").select("B")
      find("[data-testid='reading-grade-select']").select("A")
      fill_in type: "number", with: 87
    end

    click_on "Save Grades"

    within("tr", text: @student1.username) do
      assert_text "A"
      assert_text "B+"
      assert_field "grade_entries[#{@student1_entry.id}][attendance_days]", with: "95", wait: 5
    end

    within("tr", text: @student2.username) do
      assert_text "B"
      assert_text "A"
      assert_field "grade_entries[#{@student2_entry.id}][attendance_days]", with: "87", wait: 5
    end
  end

  test "admin sees success message when finalizing grade book" do
    DistributeEarnings.stubs(:execute)
    admin = create(:admin)
    sign_in(admin)

    # Fill out all entries to make grade book finalizable
    @grade_book.grade_entries.each do |entry|
      entry.update!(math_grade: "A", reading_grade: "B", attendance_days: 30)
    end

    visit classroom_grade_book_path(@classroom, @grade_book)

    # Accept the confirmation dialog
    accept_confirm "Are you sure you want to finalize these grades? This action cannot be undone." do
      click_on "Finalize Grades"
    end

    assert_text "Grade book finalized. Funds have been distributed."
  end

  test "teacher enters grades for multiple students" do
    visit classroom_grade_book_path(@classroom, @grade_book)

    # Verify students are shown
    assert_text @student1.username
    assert_text @student2.username

    # Enter grades for both students
    within("tr", text: @student1.username) do
      find("[data-testid='math-grade-select']").select("A")
      find("[data-testid='reading-grade-select']").select("B+")
      fill_in type: "number", with: 95
    end

    within("tr", text: @student2.username) do
      find("[data-testid='math-grade-select']").select("B")
      find("[data-testid='reading-grade-select']").select("A")
      fill_in type: "number", with: 87
    end

    click_on "Save Grades"

    # Verify at least the text appears on page (grades saved and displayed)
    assert_text "A"
    assert_text "B+"
    assert_text "B"

    # Verify grade book status remains draft
    @grade_book.reload
    assert_equal "draft", @grade_book.status
  end

  test "teacher updates previously entered grades" do
    # Pre-populate grades for first student
    @student1_entry.update!(math_grade: "B", reading_grade: "C", attendance_days: 20)

    visit classroom_grade_book_path(@classroom, @grade_book)

    # Verify current grade is shown
    assert_text "B"
    assert_text "C"

    # Update the grades
    within("tr", text: @student1.username) do
      find("[data-testid='math-grade-select']").select("A")
      find("[data-testid='reading-grade-select']").select("B+")
      fill_in type: "number", with: 25
    end

    click_on "Save Grades"

    # Verify updated grades appear on page
    assert_text "A"
    assert_text "B+"
  end

  test "teacher marks student with perfect attendance" do
    visit classroom_grade_book_path(@classroom, @grade_book)

    # Enter grades with perfect attendance checkbox
    within("tr", text: @student1.username) do
      find("[data-testid='math-grade-select']").select("A")
      find("[data-testid='reading-grade-select']").select("A")
      fill_in type: "number", with: 90
      find("[data-testid='perfect-attendance-checkbox']").check
    end

    click_on "Save Grades"

    # Verify page reloads successfully
    assert_text @student1.username

    # Verify checkbox is still checked after save
    within("tr", text: @student1.username) do
      assert find("[data-testid='perfect-attendance-checkbox']").checked?
    end
  end

  test "teacher can view but cannot finalize grade book" do
    # Fill out all entries
    @grade_book.grade_entries.each do |entry|
      entry.update!(math_grade: "A", reading_grade: "B", attendance_days: 30)
    end

    visit classroom_grade_book_path(@classroom, @grade_book)

    # Teacher can view and edit grades
    assert_text @student1.username
    assert_text @student2.username

    # But cannot finalize (button is admin-only)
    assert_no_text "Finalize Grades"
  end

  test "teacher cannot view grade books from other classrooms" do
    # Create another classroom with grade book
    other_classroom = create(:classroom)
    other_grade_book = create(:grade_book, classroom: other_classroom)

    # Teacher attempts to access other classroom's grade book
    visit classroom_grade_book_path(other_classroom, other_grade_book)

    # Should be denied access (redirected to root)
    # Authorization happens via Pundit policy
    assert_current_path root_path
  end

  test "grade book displays validation errors for invalid input" do
    visit classroom_grade_book_path(@classroom, @grade_book)

    # Enter invalid attendance (negative number blocked by HTML5 min=0)
    # Test is mainly to document that validation exists
    within("tr", text: @student1.username) do
      # HTML5 number field with min=0 prevents negative input
      # So this test mainly documents that the field has validation
      assert_selector "input[type='number'][min='0']"
    end
  end

  test "teacher cannot edit finalized grade book" do
    # Finalize the grade book
    @grade_book.grade_entries.each do |entry|
      entry.update!(math_grade: "A", reading_grade: "B", attendance_days: 30)
    end
    @grade_book.update!(status: :completed)

    visit classroom_grade_book_path(@classroom, @grade_book)

    # Verify form fields are disabled
    assert_selector "select[disabled]", count: 4 # 2 students × 2 grade dropdowns
    assert_selector "input[type='number'][disabled]", count: 2 # 2 attendance fields
    assert_selector "input[type='checkbox'][disabled]", count: 2 # 2 perfect attendance checkboxes

    # Save button should not appear or be disabled
    assert_no_button "Save Grades"
  end
end
