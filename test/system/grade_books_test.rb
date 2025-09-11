# frozen_string_literal: true

# test/system/grade_books_test.rb
require "application_system_test_case"

class GradeBooksTest < ApplicationSystemTestCase
  setup do
    @classroom  = create(:classroom)
    @grade_book = create(:grade_book, classroom: @classroom)

    @student1 = create(:student, classroom: @classroom)
    @student2 = create(:student, classroom: @classroom)

    create(:grade_entry, grade_book: @grade_book, user: @student1)
    create(:grade_entry, grade_book: @grade_book, user: @student2)

    @teacher = create(:teacher, classroom: @classroom)
    sign_in(@teacher)
  end

  test "teacher updates grade book entries" do
    visit classroom_grade_book_path(@classroom, @grade_book)

    # It renders the table correctly
    assert_text @student1.username
    assert_text @student2.username

    # Update grade entry values
    within("tbody tr:nth-child(1)") do
      select "A",  from: "grade_entries_#{@grade_book.grade_entries.first.id}_math_grade"
      select "B+", from: "grade_entries_#{@grade_book.grade_entries.first.id}_reading_grade"
      fill_in "grade_entries_#{@grade_book.grade_entries.first.id}_attendance_days", with: 95
    end

    within("tbody tr:nth-child(2)") do
      select "B", from: "grade_entries_#{@grade_book.grade_entries.second.id}_math_grade"
      select "A", from: "grade_entries_#{@grade_book.grade_entries.second.id}_reading_grade"
      fill_in "grade_entries_#{@grade_book.grade_entries.second.id}_attendance_days", with: 87
    end

    click_on "Save Grades"

    # Assert the values saved correctly
    within("tbody tr:nth-child(1)") do
      assert_selector(
        "select[name='grade_entries[#{@grade_book.grade_entries.first.id}][math_grade]'] option[selected]",
        text: "A"
      )
      assert_selector(
        "select[name='grade_entries[#{@grade_book.grade_entries.first.id}][reading_grade]'] option[selected]",
        text: "B+"
      )
      assert_field(
        "grade_entries[#{@grade_book.grade_entries.first.id}][attendance_days]",
        with: "95"
      )
    end

    within("tbody tr:nth-child(2)") do
      assert_selector(
        "select[name='grade_entries[#{@grade_book.grade_entries.second.id}][math_grade]'] option[selected]",
        text: "B"
      )
      assert_selector(
        "select[name='grade_entries[#{@grade_book.grade_entries.second.id}][reading_grade]'] option[selected]",
        text: "A"
      )
      assert_field(
        "grade_entries[#{@grade_book.grade_entries.second.id}][attendance_days]",
        with: "87"
      )
    end
  end
end
