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
  # has to be readable as text.
  test "the trading setting says what it is and what it does" do
    classroom = create(:classroom, :with_trading)
    teacher_viewing(classroom)

    visit classroom_path(classroom)

    assert_text "Trading on"
    assert_text "Students can buy and sell shares."
    assert_text "Turning this off stops new orders"
    assert_selector "label", text: "Turn off"
  end

  test "the trading setting explains the off state, and says when" do
    classroom = create(:classroom, trading_enabled: false)
    teacher_viewing(classroom)

    visit classroom_path(classroom)

    assert_text "Trading off"
    assert_text "Students cannot buy or sell."
    assert_text "with a note explaining why"
    assert_text "Off since"
    assert_selector "label", text: "Turn on"
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

  # The roster is why a teacher opens this page, so it has to be on screen. 567px of a 625px viewport
  # was the first attempt at this redesign, with a stat band above the setting card.
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

      assert_operator top, :<, 340,
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
      assert_text "Draft"
    end
  end
end
