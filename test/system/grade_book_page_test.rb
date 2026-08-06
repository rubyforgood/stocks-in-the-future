# frozen_string_literal: true

require "application_system_test_case"

# grade_books#show against design.md. Reported as "does not match the design system at all", and the
# audit agreed - every figure below is what it measured before the fix:
#
#   - the grades table sat on **no surface**: 0px border, transparent background, 0px radius, on a
#     slate-50 page. classrooms#show's roster had exactly this defect and design.md records it as fixed
#     there; this page hand-rolled its own `overflow-x-auto` to get the keyboard-scroll attributes and
#     lost the card doing it.
#   - the perfect-attendance checkbox was **187x44px**, because it carried `tw-input-primary` - the text
#     input class.
#   - the grade book's own status was **nowhere on the page**, while the classroom list shows it on every
#     row.
#   - form actions were centred, in two separate stacks, and "Finalize grades" was a second filled
#     primary against design.md's one-per-page rule.
#
# I linked to this page four times from a section I rebuilt twice and never opened it.
class GradeBookPageTest < ApplicationSystemTestCase
  def a_grade_book_with_entries
    classroom = create(:classroom, :with_trading)
    2.times { create(:student, :with_portfolio, classroom:) }
    book = classroom.grade_books.first
    classroom.users.students.each { |s| create(:grade_entry, grade_book: book, user: s) }
    [classroom, book]
  end

  def teacher_for(classroom)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    teacher
  end

  test "the grades table sits on the same card surface as every other table" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    surface = page.evaluate_script(<<~JS)
      (function () {
        const wrap = document.querySelector("main table").parentElement;
        const cs = getComputedStyle(wrap);
        return { border: cs.borderTopWidth, bg: cs.backgroundColor, radius: cs.borderTopLeftRadius,
                 klass: wrap.className };
      })()
    JS

    assert_includes surface["klass"], "table-wrapper",
                    "the table is not on shared/_table_container"
    assert_equal "1px", surface["border"]
    assert_equal "rgb(255, 255, 255)", surface["bg"]
    assert_equal "16px", surface["radius"]
  end

  # The keyboard-scroll affordance the hand-rolled wrapper existed for has to survive moving onto the
  # container, or the columns past the right edge are unreachable without a mouse.
  test "the grades table is still keyboard scrollable" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    wrap = find("main table").find(:xpath, "..")

    assert_equal "0", wrap[:tabindex]
    assert_equal "region", wrap[:role]
    assert_equal "Grades", wrap["aria-label"]
  end

  test "the perfect attendance checkbox is a checkbox" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    box = page.evaluate_script(<<~JS)
      (function () {
        const el = document.querySelector("[data-testid='perfect-attendance-checkbox']");
        const b = el.getBoundingClientRect();
        return [Math.round(b.width), Math.round(b.height)];
      })()
    JS

    assert_equal [16, 16], box,
                 "the checkbox measures #{box.inspect}; it is carrying the text input class"
  end

  # The native <select> arrow's inset cannot be controlled: the field is px-3 and Chrome draws its own
  # glyph hard against the right edge of that padding, so it sat visibly tighter to the border than any
  # other control's contents. Replaced with our own chevron, positioned to match the field's px-3.
  test "the select chevron is inset like the rest of the field" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    style = page.evaluate_script(<<~JS)
      (function () {
        const cs = getComputedStyle(document.querySelector("main select"));
        return { appearance: cs.appearance, paddingRight: cs.paddingRight,
                 position: cs.backgroundPosition };
      })()
    JS

    assert_equal "none", style["appearance"], "the native arrow is back, and its inset is not ours"
    assert_equal "36px", style["paddingRight"], "a long option can run under the chevron"
    assert_includes style["position"], "12px",
                    "the chevron should sit 12px from the edge, matching the field's px-3"
  end

  # design.md states this for an actions column and for numeric ones. This table's last column is
  # neither, and was the only left-aligned trailing column in the app - which is what made it look wrong
  # beside every other table.
  test "the trailing column is right aligned, header and cells" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    align = page.evaluate_script(<<~JS)
      (function () {
        const ths = document.querySelectorAll("main thead th");
        const cell = document.querySelector("[data-testid='perfect-attendance-checkbox']").closest("td");
        return [getComputedStyle(ths[ths.length - 1]).textAlign, getComputedStyle(cell).textAlign];
      })()
    JS

    assert_equal %w[right right], align,
                 "the trailing column is #{align.inspect}; every other table's right-aligns"
  end

  # A <th> names a data cell, not a form control - so a screen reader met four unnamed controls per row
  # and could not tell a math grade from a reading grade, or whose row it was in. Rails' hidden companion
  # input for a checkbox is excluded: it is not exposed to assistive tech.
  test "every control in the grades table names itself" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    unnamed = page.evaluate_script(<<~JS)
      (function () {
        const out = [];
        document.querySelectorAll("main tbody select, main tbody input").forEach(function (el) {
          if (el.type === "hidden") return;
          if (!el.getAttribute("aria-label") && !el.labels.length) out.push(el.name || el.type);
        });
        return out;
      })()
    JS

    assert_empty unnamed, "controls with no accessible name: #{unnamed.inspect}"
  end

  # The column is a flat bonus on top of the per-day rate, and the table never said so. Interpolated from
  # GradeEntry's constants, so the copy cannot claim a rate the model does not pay.
  test "the table says what the columns pay" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    bonus = money(GradeEntry::EARNINGS_FOR_PERFECT_ATTENDANCE)

    assert_text "perfect attendance adds a #{bonus} bonus"
    assert_text money(GradeEntry::EARNINGS_PER_DAY_ATTENDANCE)
  end

  def money(cents)
    ActiveSupport::NumberHelper.number_to_currency(cents / 100.0)
  end

  test "the page says which state the grade book is in" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_selector "h1", text: book.quarter.name
    assert_text "Draft"
  end

  test "form actions are not centred" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    centred = page.evaluate_script(<<~JS)
      (function () {
        const save = document.querySelector("#submit-button");
        const main = document.querySelector("main");
        const s = save.getBoundingClientRect(), m = main.getBoundingClientRect();
        return Math.round(s.left - m.left) > 200;
      })()
    JS

    assert_not centred, "the save action is centred; form actions anchor to the leading edge"
  end

  # design.md: one filled primary per page. "Finalize grades" was a second one, and it is the action
  # that pays students and cannot be undone - so it is :danger_outline with the consequence in copy
  # beside it, which is this app's rule for a serious action.
  test "an admin sees one filled primary, and finalize explains itself" do
    classroom, book = a_grade_book_with_entries
    sign_in create(:admin)

    visit classroom_grade_book_path(classroom, book)

    primaries = page.evaluate_script(<<~JS)
      (function () {
        return Array.from(document.querySelectorAll("main .tw-btn-primary"))
          .filter(function (e) { return e.getClientRects().length; })
          .map(function (e) { return (e.value || e.textContent || "").trim(); });
      })()
    JS

    assert_equal 1, primaries.length, "two filled primaries on one page: #{primaries.inspect}"
    assert_text "Pays each student the funds their grades and attendance have earned"
    assert_text "cannot be undone"
    assert_selector ".tw-btn-danger-outline", text: "Finalize grades"
  end

  # A completed grade book has already paid out, so the control is not rendered at all rather than
  # rendered greyed.
  test "a completed grade book offers no finalize" do
    classroom, book = a_grade_book_with_entries
    book.update!(status: :completed)
    sign_in create(:admin)

    visit classroom_grade_book_path(classroom, book)

    assert_text "Completed"
    assert_no_selector "#finalize-button"
  end
end
