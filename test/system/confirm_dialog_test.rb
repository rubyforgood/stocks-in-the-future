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

  # A link-driven confirm now carries its verb too, which it could not before.
  #
  # Turbo passes a submitter for a form submission - a `button_to` - and **not** for a link carrying
  # `turbo_method`, because it synthesises the form itself and copies only five attributes onto it. So
  # ~20 confirmations said "Confirm". The controller remembers the last element clicked that carries
  # `data-turbo-confirm`, which is available whatever Turbo hands the hook.
  test "a link-driven confirm carries the control's verb" do
    classroom, = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    assert_selector "#confirm-dialog[open]"

    within("#confirm-dialog") do
      assert_selector "button", text: "Cancel"
      assert_no_selector "button", text: "OK"
      assert_no_selector "[data-confirm-dialog-target='accept']", text: "Confirm"
      assert_selector "[data-confirm-dialog-target='accept']", text: "Delete"
    end
  end

  # A confirmation's job is to say what the action does. "Reset Ada's password?" told a teacher nothing
  # they did not know when they clicked - reported as exactly that, asking whether the student gets an
  # email. They do not: the password is generated, set immediately, and shown to the teacher once.
  test "a confirmation explains what the action will do" do
    classroom, student = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Reset password", match: :first

    assert_selector "#confirm-dialog[open]"

    within("#confirm-dialog") do
      # The question is the dialog's accessible name; the consequence is its description.
      assert_selector "#confirm-dialog-message", text: "Reset #{student.display_name}'s password?"
      assert_selector "#confirm-dialog-body", text: "No email is sent"
      assert_selector "#confirm-dialog-body", text: "stops working immediately"
    end
  end

  # "This cannot be undone" was false: StudentsController#destroy discards, and User#destroy raises
  # rather than hard-delete a person, so everything attached to the account survives.
  test "a reversible action does not claim to be permanent" do
    classroom, = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    within("#confirm-dialog") do
      assert_no_text "cannot be undone"
      assert_selector "#confirm-dialog-body", text: "an administrator can restore"
    end
  end

  # A destructive accept is `.tw-btn-danger` - solid rose - and anything else is the brand primary. The
  # trigger says which, so a label containing the word "delete" is not what decides it.
  test "the accept button is destructive only for a destructive action" do
    classroom, = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    assert_selector "#confirm-dialog[open] [data-confirm-dialog-target='accept'].tw-btn-danger"
    assert_no_selector "#confirm-dialog [data-confirm-dialog-target='accept'].tw-btn-primary"

    within("#confirm-dialog") { click_on "Cancel" }

    click_on "Reset password", match: :first

    assert_selector "#confirm-dialog[open] [data-confirm-dialog-target='accept'].tw-btn-primary"
    assert_no_selector "#confirm-dialog [data-confirm-dialog-target='accept'].tw-btn-danger"
  end

  # The fill, and its contrast, measured rather than asserted on the class name. Painted into a canvas and
  # read back, because getComputedStyle returns oklch() in this browser and parsing those three numbers as
  # if they were RGB is how an audit here once invented five contrast failures.
  #
  # This test used to assert the opposite - that the accept carried no red at rest - when the rule read
  # "no red at rest, anywhere". The rule now reads "on a page", with the dialog as the named exception, so
  # the assertion inverts with it. What has not changed: a destructive control **on a page** is still
  # slate at rest, which `row_actions_test` covers.
  test "the destructive accept is a solid rose that clears AA" do
    classroom, = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    assert_selector "#confirm-dialog[open]"

    channels = page.evaluate_script(<<~JS)
      (function () {
        const el = document.querySelector("[data-confirm-dialog-target='accept']");
        const c = document.createElement("canvas");
        c.width = c.height = 1;
        const x = c.getContext("2d");
        x.fillStyle = "white";
        x.fillRect(0, 0, 1, 1);
        x.fillStyle = getComputedStyle(el).backgroundColor;
        x.fillRect(0, 0, 1, 1);
        const d = x.getImageData(0, 0, 1, 1).data;
        return { r: d[0], g: d[1], b: d[2] };
      })()
    JS

    # Red-dominant by a wide margin, which white and a hairline-bordered white are not.
    assert_operator channels["r"] - channels["g"], :>, 100,
                    "the destructive accept is not a red fill (#{channels.inspect})"

    ratio = page.evaluate_script(<<~JS)
      (function () {
        const el = document.querySelector("[data-confirm-dialog-target='accept']");
        const paint = (colour) => {
          const c = document.createElement("canvas");
          c.width = c.height = 1;
          const x = c.getContext("2d");
          x.fillStyle = "white";
          x.fillRect(0, 0, 1, 1);
          x.fillStyle = colour;
          x.fillRect(0, 0, 1, 1);
          return x.getImageData(0, 0, 1, 1).data;
        };
        const lum = (d) => {
          const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
          return 0.2126 * f(d[0]) + 0.7152 * f(d[1]) + 0.0722 * f(d[2]);
        };
        const cs = getComputedStyle(el);
        const [hi, lo] = [lum(paint(cs.color)), lum(paint(cs.backgroundColor))].sort((a, b) => b - a);
        return Math.round(((hi + 0.05) / (lo + 0.05)) * 100) / 100;
      })()
    JS

    assert_operator ratio, :>=, 4.5, "the destructive accept's label is #{ratio}:1 on its fill"
  end

  # The body is hidden rather than empty when a confirmation has nothing to add, so a one-line question
  # does not sit above a gap.
  test "a confirmation with no body leaves no gap" do
    classroom, = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Reset password", match: :first

    height = page.evaluate_script(<<~JS)
      (function () {
        const body = document.querySelector("#confirm-dialog-body");
        body.textContent = "";
        body.classList.add("hidden");
        return Math.round(body.getBoundingClientRect().height);
      })()
    JS

    assert_equal 0, height
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

  # The two accidental dismissals, which were the ones missing when this was first written - and they are
  # the likeliest: a stray Enter, and a click at the edge of the screen. Both must decline.
  test "enter declines, because focus starts on the safe option" do
    classroom, student = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    assert_selector "#confirm-dialog[open]"

    page.driver.browser.action.send_keys(:enter).perform

    assert_no_selector "#confirm-dialog[open]"

    # A bounded wait, and it is load-bearing. Proving that *nothing* happened has no positive state to
    # wait on: without it this read the database before the DELETE had finished and passed whichever
    # button Enter had pressed. Checked by moving `autofocus` onto the accept button - the test failed
    # then and passes now.
    sleep 0.5

    assert_not student.reload.discarded?, "Enter confirmed a destructive action"
    assert_no_selector "#notice"
  end

  # A native <dialog> does not close on a backdrop click, so this is ours: a click whose target is the
  # dialog element itself landed outside the panel.
  test "a backdrop click declines" do
    classroom, student = a_classroom_with_a_student

    visit classroom_path(classroom)
    click_on "Delete", match: :first

    assert_selector "#confirm-dialog[open]"

    top = page.evaluate_script(
      "Math.round(document.querySelector('#confirm-dialog').getBoundingClientRect().top)"
    )
    page.driver.browser.action.move_to_location(5, top + 5).click.perform

    assert_no_selector "#confirm-dialog[open]"
    assert_not student.reload.discarded?, "a backdrop click confirmed a destructive action"
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
