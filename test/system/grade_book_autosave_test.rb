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

    # The heading is the button's own words - it named "the quarter" while the button said "grades".
    assert_selector "#finalize-heading", text: "Finalize grades"
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

  # **The status line barely moves.** It used to change three times per edit - "Saving…", "All changes
  # saved", then a new timestamp - which on a 25-student book is about three hundred redraws in one spot
  # while a teacher works. Reported as distracting, and it was.
  test "an ordinary edit does not redraw the save status at all" do
    classroom, book, = a_grade_book
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher
    visit classroom_grade_book_path(classroom, book)

    page.execute_script(<<~JS)
      window.__redraws = 0;
      new MutationObserver(() => { window.__redraws += 1; })
        .observe(document.querySelector("[data-testid='autosave-status']"),
                 { childList: true, characterData: true, subtree: true });
    JS

    find("[data-testid='attendance-days-input']").set("12")
    find("h1").click

    # The point of this change is that a save is now *silent*, so there is no status text to wait on -
    # which means the assertion below would otherwise race the request. The earnings cell is what does
    # change (0 days to 12 is $2.40), and Capybara waits on it.
    assert_selector "[data-testid='row-earnings']", text: "$2.40", wait: 5
    assert_equal 12, book.grade_entries.first.reload.attendance_days, "the edit did not save"
    assert_equal 0, page.evaluate_script("window.__redraws"),
                 "the save status was rewritten for a routine save"
  end

  test "a save that is still running after a moment says so" do
    classroom, book, = a_grade_book
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher
    visit classroom_grade_book_path(classroom, book)

    # The pending state is time-based, so it is driven directly rather than by hoping a request is slow.
    page.execute_script(
      "document.querySelector('form[data-autosave-target=\"form\"]')" \
      ".dispatchEvent(new CustomEvent('turbo:submit-start', { bubbles: true }))"
    )

    assert_selector "[data-testid='autosave-status']", text: "Saving"
  end

  # The one state a teacher has to act on, and the one this never handled.
  test "a failed save says so and stays said" do
    classroom, book, = a_grade_book
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher
    visit classroom_grade_book_path(classroom, book)

    page.execute_script(<<~JS)
      document.querySelector('form[data-autosave-target="form"]').dispatchEvent(
        new CustomEvent("turbo:submit-end", { bubbles: true, detail: { success: false } })
      );
    JS

    assert_selector "[data-testid='autosave-status']", text: "Not saved"
    assert page.evaluate_script(
      "document.querySelector(\"[data-testid='autosave-status']\").classList.contains('text-red-700')"
    ), "a failure is not distinguished from the resting state"
  end
end
