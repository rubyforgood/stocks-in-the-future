# frozen_string_literal: true

require "application_system_test_case"

# The app's own confirmation dialog, replacing the browser's.
#
# There are 28 `data-turbo-confirm` call sites - links, `button_to` forms and helper-generated row
# actions, including the one that finalizes a grade book and deposits real money into every student's
# portfolio - and every one of them was an unstyled OS dialog whose buttons said "OK" and "Cancel".
#
# The thing worth testing is not that it looks right, it is that **it still confirms**. A custom confirm
# that resolves wrongly either performs a destructive action nobody agreed to, or silently refuses one
# they did. Both directions are asserted here, on a real destructive action rather than a fixture.
class ConfirmDialogTest < ApplicationSystemTestCase
  def a_classroom_with_a_student
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:, name: "Jordan Smith", username: "jsmith")
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    [classroom, student]
  end

  test "the dialog replaces the native confirm and carries the message" do
    classroom, = a_classroom_with_a_student

    visit classroom_path(classroom)

    assert_no_selector "#confirm-dialog[open]"

    click_on "Delete", match: :first

    assert_selector "#confirm-dialog[open]"
    within("#confirm-dialog") { assert_text "Delete" }
  end

  # The accept button takes the verb from the control that was pressed, where there is one. Turbo passes a
  # submitter for a form submission - a `button_to` - and **not** for a link carrying `turbo_method`,
  # because it synthesises the form itself. So a link falls back to "Confirm", which is honest: the app
  # cannot know the verb, and inferring it from the message's first word breaks on the several that begin
  # "Are you sure...".
  test "a link-driven confirm falls back to a generic verb" do
    classroom, = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    assert_selector "#confirm-dialog[open]"

    within("#confirm-dialog") do
      assert_selector "button", text: "Cancel"
      assert_no_selector "button", text: "OK"
      assert_selector "[data-confirm-dialog-target='accept']", text: "Confirm"
    end
  end

  # And where Turbo does pass one, the button names the action: "Finalize grades", not "OK".
  test "a button_to confirm carries the control's own verb" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:, name: "Jordan Smith")
    book = classroom.grade_books.first
    create(:grade_entry, grade_book: book, user: student)
    sign_in create(:admin)

    visit classroom_grade_book_path(classroom, book)
    click_on "Finalize grades"

    assert_selector "#confirm-dialog[open]"

    within("#confirm-dialog") do
      assert_selector "[data-confirm-dialog-target='accept']", text: "Finalize grades"
      assert_text "cannot be undone"
    end
  end

  # The direction that matters most: cancelling must not perform the action.
  test "cancelling does not perform the action" do
    classroom, student = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    within("#confirm-dialog") { click_on "Cancel" }

    assert_no_selector "#confirm-dialog[open]"
    assert_text student.display_name
    assert_not student.reload.discarded?, "cancelling the dialog still deleted the student"
  end

  # And the other direction: confirming must actually perform it, or a custom confirm has quietly broken
  # every destructive action in the app.
  test "confirming performs the action" do
    classroom, student = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    within("#confirm-dialog") { find("[data-confirm-dialog-target='accept']").click }

    assert_selector "#notice"
    assert student.reload.discarded?, "confirming the dialog did not delete the student"
  end

  # Escape is the browser's, not ours - a native <dialog> gives it for free - but it has to resolve the
  # promise false rather than leave it hanging, or the page is stuck with an inert body.
  test "escape dismisses and declines" do
    classroom, student = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    find("#confirm-dialog").send_keys(:escape)

    assert_no_selector "#confirm-dialog[open]"
    assert_not student.reload.discarded?

    # The page is still usable afterwards, which is what proves the promise settled.
    click_on "Delete", match: :first

    assert_selector "#confirm-dialog[open]"
  end

  # Cancel takes focus, so a stray Enter declines rather than confirms a destructive action.
  test "focus starts on cancel" do
    classroom, = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    # Waiting for the dialog before reading focus: `click_on` does not block, so reading activeElement
    # straight after it races showModal() and reports the trigger.
    assert_selector "#confirm-dialog[open]"

    focused = page.evaluate_script("document.activeElement.textContent.trim()")

    assert_equal "Cancel", focused, "focus should start on the safe option"
  end

  # Three sizing classes, and I got them wrong twice - so the geometry is asserted rather than eyeballed.
  #
  # Tailwind's preflight resets `dialog { margin: 0 }`, which kills the UA stylesheet's `margin: auto`:
  # without `m-auto` the panel sat hard against the **left** edge at every width (measured left=0 with
  # 918px spare at 1366px). And the UA sets `dialog { width: fit-content }`, so without `w-auto` it was
  # sized by its own message - 301px whatever the viewport - instead of filling to `max-w-md`.
  test "the dialog is centred, and clears the page gutter on a phone" do
    classroom, = a_classroom_with_a_student

    in_chromebook_viewport do
      visit classroom_path(classroom)
      click_on "Delete", match: :first

      assert_selector "#confirm-dialog[open]"

      box = dialog_box

      assert_equal 448, box["width"], "the panel should be max-w-md on a wide screen"
      assert_in_delta box["left"], box["right"], 2, "the panel is not centred: #{box.inspect}"
    end
  end

  test "the dialog keeps a 16px gutter at phone width" do
    classroom, = a_classroom_with_a_student

    in_phone_viewport do
      visit classroom_path(classroom)
      click_on "Delete", match: :first

      assert_selector "#confirm-dialog[open]"

      box = dialog_box

      assert_equal 16, box["left"], "the panel touches the left edge: #{box.inspect}"
      assert_equal 16, box["right"], "the panel touches the right edge: #{box.inspect}"
    end
  end

  def dialog_box
    page.evaluate_script(<<~JS)
      (function () {
        const b = document.querySelector("#confirm-dialog").getBoundingClientRect();
        const doc = document.documentElement.clientWidth;
        return { width: Math.round(b.width), left: Math.round(b.left),
                 right: Math.round(doc - b.right) };
      })()
    JS
  end

  # It is registered once for the whole app, so it has to work on the admin side too - which carries most
  # of the destructive actions.
  test "admin gets the same dialog" do
    create(:classroom, :with_trading)
    sign_in create(:admin)

    visit admin_classrooms_path

    assert_selector "#confirm-dialog", visible: :all
  end
end
