# frozen_string_literal: true

require "application_system_test_case"

# The teacher's classroom page, against the three things reported about it.
#
#   - The roster and the grade books sat side by side, 765px against 256px at 1366px. Polaris, whose
#     two-column layout that imitated, reserves the narrow column for metadata rather than a second
#     collection; Stripe, GitHub and Linear all stack an entity's related collections full width.
#   - The trading switch was a bare track in the page header's action area, so the one control that
#     changes what students can do sat among the navigation, and its state was carried by colour alone.
#   - Nothing said what it did.
#
# Measured at 1366x768 through the change: the roster's first row went 146px -> 567px on the first
# attempt, which put it below a 625px fold, and then to 296px once the summary band came out and the
# setting card lost its redundant header. The table went 765px -> 1045px.
class ClassroomPageTest < ApplicationSystemTestCase
  def teacher_viewing(classroom)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)
    teacher
  end

  # The reported problem, asserted as geometry rather than as markup: whatever the classes say, the
  # grade books must begin below the roster and both must have the column's full width.
  test "the roster and the grade books are stacked, not side by side" do
    classroom = create(:classroom, :with_trading)
    2.times { create(:student, :with_portfolio, classroom:) }
    teacher_viewing(classroom)

    in_chromebook_viewport do
      visit classroom_path(classroom)

      boxes = page.evaluate_script(<<~JS)
        (function () {
          const table = document.querySelector("table");
          const books = document.querySelector("#grade-books-heading");
          const t = table.getBoundingClientRect(), b = books.getBoundingClientRect();
          return { tableBottom: Math.round(t.bottom), tableWidth: Math.round(t.width),
                   booksTop: Math.round(b.top), booksWidth: Math.round(b.width) };
        })()
      JS

      assert_operator boxes["booksTop"], :>=, boxes["tableBottom"],
                      "the grade books start beside the roster rather than under it"
      assert_in_delta boxes["tableWidth"], boxes["booksWidth"], 8,
                      "one section is narrower than the other, which reads as subordinate"
    end
  end

  # A switch whose state is carried by the track's colour is the thing that "makes no sense". The state
  # has to be readable as text, in the sentence beside the control.
  test "the trading setting says what it is and what it does" do
    classroom = create(:classroom, :with_trading)
    teacher_viewing(classroom)

    visit classroom_path(classroom)

    assert_text "Trading is on."
    assert_text "Students can buy and sell shares."
    assert_text "does not sell anything"
  end

  test "the trading setting explains the off state, and says when" do
    classroom = create(:classroom, trading_enabled: false)
    teacher_viewing(classroom)

    visit classroom_path(classroom)

    assert_text "Trading is off."
    assert_text "Students cannot buy or sell"
    assert_text "a note explains why"
    assert_text "Off since"
  end

  # The switch is labelled with the noun, not a verb. A switch's position is its state - iOS, Material
  # and Polaris all pair a noun with a switch - and Polaris's verb belongs on a button. "Turn on" beside
  # a pill saying "Trading off" was two things to reconcile.
  test "the trading switch is labelled with the noun and carries no status pill" do
    classroom = create(:classroom, trading_enabled: false)
    teacher_viewing(classroom)

    visit classroom_path(classroom)

    label = find("label", text: "Trading")

    assert_equal "Trading", label.text.strip,
                 "the switch label should be the noun, not a verb or a state"

    row = label.find(:xpath, "../..")

    assert_not row.has_selector?("span.rounded-full", wait: 0),
               "a status pill sits beside the state sentence; the sentence already says the state"
  end

  # "There is no padding around the white circle within the green oblong." There was not: the thumb was
  # a `::after` at `size-4` with `translate-x-full`, and the track's padding box is 34x18 - so a 16px
  # thumb at a 2px inset sat flush against the bottom always, and flush against the right when checked.
  #
  # It survived three passes over that markup because a pseudo-element has no box: getBoundingClientRect
  # cannot see it, so nothing could measure the gap. The thumb is a real element now, which is what makes
  # this test possible at all.
  test "the switch thumb is evenly inset in both states" do
    classroom = create(:classroom, trading_enabled: false)
    teacher_viewing(classroom)

    visit classroom_path(classroom)

    assert_equal [2, 2, 2], thumb_insets.values_at("top", "bottom", "left"),
                 "the thumb is not evenly inset while off: #{thumb_insets.inspect}"

    find("label", text: "Trading").click
    assert_text "Trading is on."

    on = thumb_insets

    assert_equal [2, 2, 2], on.values_at("top", "bottom", "right"),
                 "the thumb is not evenly inset while on: #{on.inspect}"
    assert_equal 18, on["left"], "the thumb did not travel the full track"
  end

  # Insets measured from inside the track's border, which is where the gap is judged by eye.
  def thumb_insets
    page.evaluate_script(<<~JS)
      (function () {
        const track = document.querySelector(".tw-switch");
        const thumb = document.querySelector(".tw-switch-thumb");
        const t = track.getBoundingClientRect(), k = thumb.getBoundingClientRect();
        const b = parseFloat(getComputedStyle(track).borderTopWidth);
        return {
          top: Math.round(k.top - t.top - b),
          bottom: Math.round(t.bottom - b - k.bottom),
          left: Math.round(k.left - t.left - b),
          right: Math.round(t.right - b - k.right)
        };
      })()
    JS
  end

  # The input is sr-only, so without this a keyboard user focuses something invisible.
  test "the switch shows focus" do
    classroom = create(:classroom, :with_trading)
    teacher_viewing(classroom)

    visit classroom_path(classroom)

    outline = page.evaluate_script(<<~JS)
      (function () {
        const input = document.querySelector(".tw-switch").previousElementSibling;
        input.focus();
        return getComputedStyle(document.querySelector(".tw-switch")).outlineWidth;
      })()
    JS

    assert_equal "2px", outline, "the track shows no focus ring when its input is focused"
  end

  # **One surface per section, never one per item.**
  #
  # Six card surfaces on one page was reported as too many: the trading card, the roster's table card,
  # and one per grade book. Four quarters with a name and a status are list rows in one card, which is
  # what Polaris's ResourceList and Primer's Box rows are.
  #
  # This asserted a bare `<= 2`, which was the count on the day it was written rather than the rule. A
  # third section - the class summary - is not card soup, and four `_stat` cards inside it would have
  # been; they are one card of four figures, via `surface: false`. Counting against the sections keeps
  # the assertion true as the page grows and still fails the moment a list starts putting a card per row.
  test "the page carries one surface per section, never one per item" do
    classroom = create(:classroom, :with_trading)
    2.times { create(:student, :with_portfolio, classroom:) }
    teacher_viewing(classroom)

    visit classroom_path(classroom)

    counts = page.evaluate_script(<<~JS)
      (function () {
        return {
          surfaces: document.querySelectorAll("main .tw-card, main .table-wrapper").length,
          sections: document.querySelectorAll("main section").length
        };
      })()
    JS

    assert_operator counts["sections"], :>=, 3, "expected the roster, the grade books and the summary"
    assert_operator counts["surfaces"], :<=, counts["sections"],
                    "#{counts['surfaces']} card surfaces across #{counts['sections']} sections; " \
                    "a card per list item is card soup"
  end

  # A setting is not a page action. The header carries navigation and the primary action; a control that
  # changes what students can do belongs in the page body, where it can be explained.
  test "the trading control is not in the page header" do
    classroom = create(:classroom, :with_trading)
    teacher_viewing(classroom)

    visit classroom_path(classroom)

    header_has_switch = page.evaluate_script(<<~JS)
      (function () {
        const h1 = document.querySelector("main h1");
        const header = h1.closest("div").parentElement;
        return !!header.querySelector("input[type='checkbox']");
      })()
    JS

    assert_not header_has_switch,
               "the trading switch is back in the page header, among the page's actions"
  end

  # The roster is why a teacher opens this page, so it has to be on screen. 567px of a 625px viewport was
  # the first attempt at this redesign, with a stat band above a setting card; 296px was the second, with
  # the setting still in a card of its own. Folding the setting into the section's own header row got it
  # to 206px, which is the figure design.md set for the trading floor.
  test "the roster's first row is on screen on a Chromebook" do
    classroom = create(:classroom, :with_trading)
    3.times { create(:student, :with_portfolio, classroom:) }
    teacher_viewing(classroom)

    in_chromebook_viewport do
      visit classroom_path(classroom)

      top = page.evaluate_script(<<~JS)
        (function () {
          const row = document.querySelector("tbody tr");
          const main = document.querySelector("main");
          return Math.round(row.getBoundingClientRect().top - main.getBoundingClientRect().top);
        })()
      JS

      # 260, raised from 240 when the page gained a breadcrumb trail. Measured: the trail is 20px tall with
      # a 24px margin, so it costs **44px** and the first row moved 206 -> 250. The property this protects is
      # that the roster's first row is on screen in a 625px viewport, and 250 clears that comfortably; the
      # threshold is deliberately only 10px above where the page sits, so the *next* block added above the
      # roster still fails here. That is the rule this page has already paid for twice - a stat band put the
      # first student at 567px of 625.
      assert_operator top, :<, 260,
                      "the first student sits #{top}px down; the viewport is 625px and the roster is " \
                      "what this page is for"
    end
  end

  # The rail could not show a quarter's state, so a teacher opened all four to find the one they wanted.
  test "each grade book shows its status" do
    classroom = create(:classroom, :with_trading)
    teacher_viewing(classroom)

    visit classroom_path(classroom)

    within("section[aria-labelledby='grade-books-heading']") do
      assert_selector "a", minimum: 1
      # One mapping for the label, shared with the grade book page, so the two cannot disagree.
      assert_text "Not finalized"
      assert_no_text "Draft"
    end
  end

  # ClassroomFacade#stats computed four figures on every teacher's and admin's visit and no template read
  # them. They are at the foot of the page rather than the top, which is measured rather than chosen: a
  # four-across band above the roster once put the first student at 567px of a 625px screen.
  test "the class summary is rendered, and below the roster" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_00)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    in_chromebook_viewport do
      visit classroom_path(classroom)

      assert_selector "h2", text: "How this class is doing"
      assert_selector "[data-testid='stat-students']", text: "1"
      assert_selector "[data-testid='stat-portfolio-value']", text: "$100.00"

      order = page.evaluate_script(<<~JS)
        (function () {
          const y = (sel) => document.querySelector(sel).getBoundingClientRect().top + window.scrollY;
          return {
            roster: Math.round(y("table")),
            summary: Math.round(y("[data-testid='stat-students']"))
          };
        })()
      JS

      assert_operator order["summary"], :>, order["roster"],
                      "the summary is above the roster, which is what this page is for"
    end
  end

  test "a student sees no class summary" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    sign_in student
    visit classroom_path(classroom)

    assert_no_selector "h2", text: "How this class is doing"
  end
end
