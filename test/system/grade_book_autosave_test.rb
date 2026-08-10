# frozen_string_literal: true

require "application_system_test_case"

# The grade book has two actions and pays real money with one of them, so the order between them has to
# be true rather than merely stated.
#
# Finalizing pays whatever is in the **database**. The page used to autosave on a 30-second timer and
# nothing else - not on blur, not on change - so a teacher could type a grade, press Finalize inside that
# window, and pay the previous one. Nothing on the page said so.
class GradeBookAutosaveTest < ApplicationSystemTestCase
  def a_grade_book
    classroom = create(:classroom, grades: [create(:grade, level: 5, name: "5th Grade")])
    student = create(:student, :with_portfolio, classroom:, name: "Ada Lovelace")
    book = classroom.grade_books.first
    entry = create(:grade_entry, grade_book: book, user: student, attendance_days: 0)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    [classroom, book, entry, teacher]
  end

  test "leaving a field saves it, without waiting for the timer" do
    classroom, book, entry, teacher = a_grade_book
    sign_in teacher
    visit classroom_grade_book_path(classroom, book)

    # `data-testid`, not the aria-label: Capybara only matches aria-label with `enable_aria_label`, which
    # this suite does not set - every other grade book test finds this field the same way.
    find("[data-testid='attendance-days-input']").set("12")
    # Blur, which is the whole point: no timer, no submit click.
    find("h1").click

    assert_selector "[data-testid='autosave-status']", text: "All changes saved"
    assert_equal 12, entry.reload.attendance_days,
                 "leaving the field did not save it, so Finalize would pay the previous value"
  end

  test "the save state is beside the button that saves, and says so before anything is typed" do
    classroom, book, = a_grade_book
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher
    visit classroom_grade_book_path(classroom, book)

    status = find("[data-testid='autosave-status']")

    # It used to live in the page header, and be empty until the first save - which is what an unsaved
    # page looks like too.
    assert_equal "All changes saved", status.text

    gap = page.evaluate_script(<<~JS)
      (function () {
        const status = document.querySelector("[data-testid='autosave-status']");
        const button = document.querySelector("#submit-button button");
        return Math.round(status.getBoundingClientRect().left - button.getBoundingClientRect().right);
      })()
    JS

    assert_operator gap, :<, 40, "the save state is not beside the button that produces it"
    assert_operator gap, :>, 0, "the save state overlaps the button"
  end

  test "the finalize card says what it acts on, and when" do
    classroom, book, = a_grade_book
    sign_in create(:admin)
    visit classroom_grade_book_path(classroom, book)

    assert_text "Then finalize the quarter"
    assert_text "Uses your saved grades, above."
  end

  # The autosave timer clicks `buttonTarget`, which is the *first* matching target in the DOM. The
  # finalize button carried that target too, so the only thing standing between a thirty-second timer and
  # an automatic payout was the order the two render in.
  test "the finalize button is not something the autosave timer can click" do
    classroom, book, = a_grade_book
    sign_in create(:admin)
    visit classroom_grade_book_path(classroom, book)

    targets = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("[data-autosave-target='button']"))
           .map(function (el) { return el.textContent.trim(); })
    JS

    assert_equal ["Save grades"], targets,
                 "an autosave target other than Save can be clicked by the timer"
  end
end
