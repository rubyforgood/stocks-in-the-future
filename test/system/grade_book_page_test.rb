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

  # A bare checkbox said nothing about what was being answered - GOV.UK reserves a single checkbox for
  # opting in and gives a yes/no question radios. Two native radios, so the keyboard behaviour is the
  # browser's, and the selected option is a light raised surface rather than a brand fill: a saturated
  # chip repeated down 25 rows is the over-emphasis the row-action rule forbids for buttons.
  test "perfect attendance is an explicit yes or no, on radios" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    control = find("[data-testid='perfect-attendance-control']", match: :first)

    assert_equal %w[Yes No], control.all("label").map(&:text)
    assert_equal 2, control.all("input[type='radio']", visible: :all).size

    assert_no_selector "[data-testid='perfect-attendance-checkbox']"
  end

  # Inputs are sized to their content. The days field rendered at 322px for a value that cannot exceed
  # two digits, because tw-input-primary is w-full and the column took the table's slack. GOV.UK states
  # the rule and ships width modifiers for exactly this.
  test "the inputs are sized to what they hold" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    widths = page.evaluate_script(<<~JS)
      (function () {
        function w(sel) { return Math.round(document.querySelector(sel).getBoundingClientRect().width); }
        return { days: w("[data-testid='attendance-days-input']"), grade: w("[data-testid='math-grade-select']") };
      })()
    JS

    assert_operator widths["days"], :<=, 96, "the days input is #{widths['days']}px for two digits"
    assert_operator widths["grade"], :<=, 120, "the grade select is #{widths['grade']}px for two characters"
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

  # The last column right-aligns, header and cells - design.md states it for actions and for numerics,
  # and every other table in the app satisfied it because every other one ends in actions. Earns is the
  # trailing column now and it is numeric, so it right-aligns on both counts; Perfect attendance sits
  # mid-table and returns to left, because the rule follows the position rather than the column.
  test "the trailing column is right aligned, header and cells" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    align = page.evaluate_script(<<~JS)
      (function () {
        const ths = document.querySelectorAll("main thead th");
        const cell = document.querySelector("[data-testid='row-earnings']");
        const total = document.querySelector("[data-testid='earnings-total']");
        return [getComputedStyle(ths[ths.length - 1]).textAlign,
                getComputedStyle(cell).textAlign,
                getComputedStyle(total).textAlign];
      })()
    JS

    assert_equal %w[right right right], align,
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

  # A teacher clicked Finalize - irreversible, and it deposits real money into every student's
  # portfolio - with no statement of what it would pay. EarningsCalculator existed for this and its
  # docstring says so; nothing had used it.
  test "each row shows what it earns, and the footer totals the column" do
    classroom, book = a_grade_book_with_entries
    book.grade_entries.each { |e| e.update!(attendance_days: 3, math_grade: "A") }
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    expected = GradeBookEarnings.new(book.reload)

    assert_selector "[data-testid='row-earnings']", count: 2
    assert_selector "[data-testid='earnings-total']",
                    text: ActiveSupport::NumberHelper.number_to_currency(expected.total_cents / 100.0)
  end

  # The figure must be the payout, not a second implementation of it.
  test "the total is what DistributeEarnings would pay" do
    _classroom, book = a_grade_book_with_entries
    book.grade_entries.each { |e| e.update!(attendance_days: 4, math_grade: "B", reading_grade: "A") }

    expected = GradeBookEarnings.new(book.reload).total_cents

    assert_difference -> { PortfolioTransaction.sum(:amount_cents) }, expected do
      book.verified!
      DistributeEarnings.execute(book)
    end
  end

  # Only the number goes in a right-aligned numeric column; an annotation in it pushes the digits off
  # the edge they align to. The warning belongs beside the field it is about.
  test "the earns column holds only the figure" do
    classroom, book = a_grade_book_with_entries
    book.grade_entries.first.update!(is_perfect_attendance: true, attendance_days: nil)
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_selector "[data-testid='unattended-bonus']", text: "No days recorded"

    within all("[data-testid='row-earnings']").first do
      assert_no_selector "span"
    end
  end

  # Both halves of the warning, which is this app's own form-error shape: a summary above, a note beside
  # the field. An entry claiming the bonus with no days is incoherent whatever the quarter's length, so
  # it can be said without the school-days figure the app does not store.
  test "a bonus with no attendance is flagged, by name and in place" do
    classroom, book = a_grade_book_with_entries
    entry = book.grade_entries.first
    entry.update!(is_perfect_attendance: true, attendance_days: nil)
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_text "set to be paid a bonus with no attendance recorded"
    assert_text entry.user.display_name
    assert_selector "[data-testid='unattended-bonus']", count: 1
  end

  test "no warning when every entry is coherent" do
    classroom, book = a_grade_book_with_entries
    book.grade_entries.each { |e| e.update!(is_perfect_attendance: false, attendance_days: 3) }
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_no_text "no attendance recorded"
    assert_no_selector "[data-testid='unattended-bonus']"
  end

  # The one place the amount reaches the person committing to it. It read "Are you sure you want to
  # finalize these grades?" and carried no figure.
  test "the confirmation names the amount and the number of students" do
    classroom, book = a_grade_book_with_entries
    book.grade_entries.each { |e| e.update!(attendance_days: 5) }
    sign_in create(:admin)

    visit classroom_grade_book_path(classroom, book)

    total = ActiveSupport::NumberHelper.number_to_currency(GradeBookEarnings.new(book.reload).total_cents / 100.0)
    confirm = find("#finalize-button button")["data-turbo-confirm"]

    assert_includes confirm, total
    assert_includes confirm, "2 students"
    assert_includes confirm, "cannot be undone"
  end

  # The action goes after the copy and the figures it acts on, not floated beside them.
  test "the finalize action sits below its explanation" do
    classroom, book = a_grade_book_with_entries
    sign_in create(:admin)

    visit classroom_grade_book_path(classroom, book)

    below = page.evaluate_script(<<~JS)
      (function () {
        const heading = document.querySelector("#finalize-heading");
        const button = document.querySelector("#finalize-button");
        return button.getBoundingClientRect().top > heading.getBoundingClientRect().bottom;
      })()
    JS

    assert below, "the finalize button is beside its explanation rather than under it"
  end

  # The one that had no excuse: in the same change I noticed the Earns figures would go stale after a
  # save and fixed them, wrote "a derived figure must refresh with whatever derives it" into CLAUDE.md,
  # and left both halves of the warning out of the same turbo_stream. Correcting the days fixed the data
  # and the notification kept accusing.
  test "the warning clears when the days are corrected" do
    classroom, book = a_grade_book_with_entries
    entry = book.grade_entries.first
    entry.update!(is_perfect_attendance: true, attendance_days: nil)
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_text "set to be paid a bonus with no attendance recorded"
    assert_selector "[data-testid='unattended-bonus']"

    within("##{dom_id(entry)}") { find("[data-testid='attendance-days-input']").set(12) }
    click_on "Save grades"

    assert_no_text "set to be paid a bonus with no attendance recorded"
    assert_no_selector "[data-testid='unattended-bonus']"
  end

  # And the other direction: creating the problem mid-edit has to raise it without a reload.
  test "the warning appears when the problem is introduced" do
    classroom, book = a_grade_book_with_entries
    entry = book.grade_entries.first
    entry.update!(is_perfect_attendance: false, attendance_days: nil)
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_no_text "set to be paid a bonus with no attendance recorded"

    within("##{dom_id(entry)}") do
      find("[data-testid='perfect-attendance-control']").find("label", text: "Yes").click
    end
    click_on "Save grades"

    assert_text "set to be paid a bonus with no attendance recorded"
  end

  # A teacher sees what the grades add up to, without the action that pays it. It used to be inside the
  # admin-only finalize block, so the person entering the grades could not see the sum while the person
  # who only presses the button could - the gate belongs on the action, not on the information.
  test "a teacher sees the total, without the admin action" do
    classroom, book = a_grade_book_with_entries
    book.grade_entries.each { |e| e.update!(attendance_days: 5, math_grade: "A") }
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    expected = GradeBookEarnings.new(book.reload)

    assert_no_selector "#earnings-summary", visible: :all
    assert_selector "#earnings-footer [data-testid='earnings-total']",
                    text: ActiveSupport::NumberHelper.number_to_currency(expected.total_cents / 100.0)

    # The action stays administrative.
    assert_no_selector "#finalize-button"
  end

  # The footer is a column summary and nothing else: one row, its label in the column where a row says
  # which row it is, its figure under the column it sums. Three more `colspan` rows carrying prose
  # labels were reported as unreadable - a row in a grid claims the headers above it describe it, and
  # "Attendance, including bonuses" spanning five unrelated columns is described by none of them.
  test "the footer is one total row, not a second table" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_selector "main table tfoot#earnings-footer"
    assert_selector "#earnings-footer tr", count: 1
    assert_selector "#earnings-footer th[scope='row']", count: 1

    # The split is not in the grid at any width.
    within("#earnings-footer") { assert_no_text "Math" }

    # The figure sits under Earns: same right edge as the per-row figures it adds up.
    edges = page.evaluate_script(<<~JS)
      (function () {
        const r = (el) => Math.round(el.getBoundingClientRect().right);
        return { total: r(document.querySelector("[data-testid='earnings-total']")),
                 row: r(document.querySelector("[data-testid='row-earnings']")) };
      })()
    JS

    assert_in_delta edges["row"], edges["total"], 1,
                    "the total is not aligned with the column it totals"
  end

  # The split into attendance, math and reading is what the payment is made of, so it sits with the
  # control that authorises it - the payroll-review shape - not in the table's grid and not in a card of
  # its own on a page that already had six surfaces.
  test "the split sits with the action that pays it" do
    classroom, book = a_grade_book_with_entries
    book.grade_entries.each { |e| e.update!(attendance_days: 5, math_grade: "A", reading_grade: "B") }
    sign_in create(:admin)

    visit classroom_grade_book_path(classroom, book)

    expected = GradeBookEarnings.new(book.reload)

    within("[aria-labelledby='finalize-heading']") do
      # The relationship is stated, not left to be inferred. Three bare amounts beside a table that
      # totals to the same figure read as a competing summary; they are the same money on the other
      # axis, and the reason they are shown at all is that the payment is written as three deposits.
      assert_text "Each student is paid in three deposits, which is how the total divides"

      # Labels name what earned the money. "Math" alone is a column of letter grades on this page.
      assert_text "Attendance, including bonuses"
      assert_text "Math grades"
      assert_text "Reading grades"

      %i[attendance math reading].each do |reason|
        assert_selector "#finalize-breakdown dd",
                        text: ActiveSupport::NumberHelper.number_to_currency(
                          expected.totals_by_reason[reason] / 100.0
                        )
      end

      # The sentence names the total; the breakdown does not restate it.
      assert_text ActiveSupport::NumberHelper.number_to_currency(expected.total_cents / 100.0)
    end
  end

  # Replaced whole on save, because every row of it is derived from the entries.
  # As an admin, so the split beside the finalize control is on the page to go stale. A teacher has no
  # finalize block, so there is nothing there to refresh - which is why the turbo_stream's replace of it
  # is allowed to find no target.
  test "the totals refresh when a grade changes" do
    classroom, book = a_grade_book_with_entries
    book.grade_entries.each { |e| e.update!(attendance_days: nil, math_grade: nil, reading_grade: nil) }
    entry = book.grade_entries.first
    sign_in create(:admin)

    visit classroom_grade_book_path(classroom, book)

    assert_selector "[data-testid='earnings-total']", text: "$0.00"

    within("##{dom_id(entry)}") { find("[data-testid='attendance-days-input']").set(10) }
    click_on "Save grades"

    expected = ActiveSupport::NumberHelper.number_to_currency(
      (10 * GradeEntry::EARNINGS_PER_DAY_ATTENDANCE) / 100.0
    )

    assert_selector "#earnings-footer [data-testid='earnings-total']", text: expected

    # And so does the split beside the action, which derives from the same entries.
    assert_selector "#finalize-breakdown dd", text: expected
  end

  # The reported bug, as an ordering: the figures come *before* the button that saves them, so nothing on
  # the page can be read as output of the save. When they were a card below "Save grades" - and above the
  # finalize block - it was unclear whether they counted what had just been typed.
  test "the totals come before the save button, with nothing between it and finalizing" do
    classroom, book = a_grade_book_with_entries
    sign_in create(:admin)

    visit classroom_grade_book_path(classroom, book)

    order = page.evaluate_script(<<~JS)
      (function () {
        const y = (sel) => {
          const el = document.querySelector(sel);
          return el ? Math.round(el.getBoundingClientRect().top + window.scrollY) : null;
        };
        return { totals: y("#earnings-footer"),
                 save: y("#submit-button"),
                 finalize: y("[aria-labelledby='finalize-heading']") };
      })()
    JS

    assert_operator order["totals"], :<, order["save"],
                    "the totals are below the save button, which is what made the flow ambiguous"
    assert_operator order["save"], :<, order["finalize"]

    # And no surface in the gap: a card there is what was reported.
    between = page.evaluate_script(<<~JS)
      (function () {
        const save = document.querySelector("#submit-button").getBoundingClientRect();
        const fin = document.querySelector("[aria-labelledby='finalize-heading']").getBoundingClientRect();
        return Array.from(document.querySelectorAll("main section, main .tw-card"))
          .filter(function (el) {
            const r = el.getBoundingClientRect();
            return r.top >= save.bottom && r.bottom <= fin.top;
          }).length;
      })()
    JS

    assert_equal 0, between, "there is still a surface between Save grades and the finalize block"
  end

  # A status is not an action, so it does not belong in the header's action slot - where it floated in
  # the top-right corner, in the place "Add student" and "Edit classroom" occupy on other pages. It goes
  # beside the name it describes.
  test "the status sits beside the title, not in the action corner" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_text "Draft"

    beside = page.evaluate_script(<<~JS)
      (function () {
        const h1 = document.querySelector("main h1");
        const pill = Array.from(document.querySelectorAll("main span"))
          .find(function (s) { return s.textContent.trim() === "Draft"; });
        if (!pill) return null;
        const a = h1.getBoundingClientRect(), b = pill.getBoundingClientRect();
        // On the title's line, and immediately after it rather than pushed to the far edge.
        return { sameLine: Math.abs(b.top - a.top) < 24, gap: Math.round(b.left - a.right) };
      })()
    JS

    assert_not_nil beside, "no Draft pill on the page"
    assert beside["sameLine"], "the status pill is not on the title's line"
    assert_operator beside["gap"], :<, 40,
                    "the status pill sits #{beside['gap']}px after the title - it is still in the corner"
  end

  # The description was a sibling of the heading *row*, so it spanned the full width and ran underneath
  # the action - at every width, not only narrow ones. A title and its subtitle are one block; the
  # actions sit beside that block.
  test "the section description does not run under the action" do
    classroom, book = a_grade_book_with_entries
    # A student missing an entry, so "Add new students" renders - it is only offered when it can act, and
    # without one this test would measure against an absent button and skip silently.
    create(:student, classroom:, name: "Late Joiner")
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    overlap = page.evaluate_script(<<~JS)
      (function () {
        const button = document.querySelector("form[action*='populate'] button, form[action*='populate'] input[type=submit]");
        const copy = Array.from(document.querySelectorAll("main p"))
          .find(function (p) { return p.textContent.includes("Each day attended earns"); });
        if (!button || !copy) return null;
        const b = button.getBoundingClientRect(), c = copy.getBoundingClientRect();
        // The copy must stay clear of the action's column, not merely below its baseline.
        return c.right > b.left;
      })()
    JS

    assert_not_nil overlap, "the populate button is not rendered, so this measured nothing"
    assert_not overlap, "the description runs under the action instead of beside it"
  end

  # "Add new students" was offered in a fully populated grade book - the normal state - where it added
  # nobody and flashed "Every student in this class already has a row". That notice auto-dismisses after
  # 6s, so the only feedback the button could produce disappeared and it looked broken. A control that can
  # only report that it did nothing is not a control.
  test "add students is not offered when there is nobody to add" do
    classroom, book = a_grade_book_with_entries
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_empty book.students_missing_entries
    assert_no_button "Add new students"
  end

  test "add students is offered, and works, when someone is missing" do
    classroom, book = a_grade_book_with_entries
    joiner = create(:student, classroom:, name: "Late Joiner")
    sign_in teacher_for(classroom)

    visit classroom_grade_book_path(classroom, book)

    assert_selector "tbody tr", count: 2
    click_on "Add new students"

    assert_selector "#notice", text: "Added 1 student"
    assert_selector "tbody tr", count: 3
    assert_text joiner.display_name
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
    assert_text "and locks these entries"
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
