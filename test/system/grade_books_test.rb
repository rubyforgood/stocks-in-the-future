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
      select "A",  from: "grade_entries_#{@student1_entry.id}_math_grade"
      select "B+", from: "grade_entries_#{@student1_entry.id}_reading_grade"
      fill_in "grade_entries_#{@student1_entry.id}_attendance_days", with: 95
    end

    within("tr", text: @student2.username) do
      select "B", from: "grade_entries_#{@student2_entry.id}_math_grade"
      select "A", from: "grade_entries_#{@student2_entry.id}_reading_grade"
      fill_in "grade_entries_#{@student2_entry.id}_attendance_days", with: 87
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
end
