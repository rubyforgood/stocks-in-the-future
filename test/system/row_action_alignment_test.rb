# frozen_string_literal: true

require "application_system_test_case"

# A row action sits on the row's first line.
#
# Reported as the Edit button not looking aligned on the classrooms table, and it was every table in the app:
# a 32px ghost and a 17px line of text both start at the cell's content edge, so the button's box top-aligned
# correctly while its centred label landed 6.5px below the row's text. Measured before the fix, on five
# tables: off by 7px, every one.
#
# The criterion is design.md's own, and it is centres rather than tops - the document states it for a lone
# checkbox ("checkbox center == the name's first-line center, not just top==top") and it applies the same way
# to a control that is taller than a line rather than shorter.
class RowActionAlignmentTest < ApplicationSystemTestCase
  # The centre of the first line of text in the row's first cell, taken with a Range so it is the glyph box
  # rather than the cell box - a cell's box tells you nothing about where its text sits.
  OFFSET = <<~JS
    (function () {
      const out = [];
      document.querySelectorAll("main tbody tr").forEach(function (tr) {
        const cells = Array.from(tr.querySelectorAll("td"))
          .filter(function (td) { return getComputedStyle(td).display !== "none"; });
        if (cells.length < 2) return;

        const walker = document.createTreeWalker(cells[0], NodeFilter.SHOW_TEXT);
        let centre = null;
        while (walker.nextNode()) {
          if (walker.currentNode.textContent.trim()) {
            const range = document.createRange();
            range.selectNodeContents(walker.currentNode);
            const rect = range.getClientRects()[0];
            if (rect) { centre = rect.top + rect.height / 2; break; }
          }
        }

        const cell = cells[cells.length - 1];
        const control = cell.querySelector("a, button");
        if (!control || centre === null || control.getClientRects().length === 0) return;

        const box = control.getBoundingClientRect();
        out.push({ label: (control.textContent || "").trim().slice(0, 14),
                   off: Math.round((box.top + box.height / 2 - centre) * 10) / 10 });
      });
      return out;
    })()
  JS

  def assert_actions_on_the_first_line(label, path)
    visit path
    rows = page.evaluate_script(OFFSET)

    assert_not_empty rows, "#{label}: found no row with both text and a trailing control"
    rows.each do |row|
      assert_in_delta 0, row["off"], 1.5,
                      "#{label}: \"#{row['label']}\" is #{row['off']}px off the row's first line"
    end
  end

  test "a teacher's tables put their row actions on the first line" do
    classroom = create(:classroom, :with_trading, name: "Test class")
    create(:student, :with_portfolio, classroom:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    assert_actions_on_the_first_line("classrooms index", classrooms_path)
    assert_actions_on_the_first_line("classroom roster", classroom_path(classroom))
  end

  test "the admin tables put their row actions on the first line" do
    school_year = create(:school_year, school: create(:school), year: create(:year))
    classroom = create(:classroom, :with_trading, school_year:)
    create(:student, :with_portfolio, classroom:)
    create(:teacher_classroom, teacher: create(:teacher), classroom:)
    create(:stock, ticker: "KO", company_name: "Coca-Cola", price_cents: 6_241)
    sign_in create(:admin)

    { "users" => admin_users_path, "students" => admin_students_path,
      "classrooms" => admin_classrooms_path, "schools" => admin_schools_path,
      "stocks" => admin_stocks_path, "teachers" => admin_teachers_path }
      .each { |label, path| assert_actions_on_the_first_line(label, path) }
  end

  # The padding that does it is on the `td`, not the `th` - the header has no control to align, and moving
  # its text would be a different bug.
  test "the header cell keeps the shared padding" do
    sign_in create(:admin)
    create(:school)

    visit admin_schools_path

    padding = page.evaluate_script(<<~JS)
      (function () {
        const th = document.querySelector("main th.table-actions-pinned");
        const td = document.querySelector("main td.table-actions-pinned");
        return { header: getComputedStyle(th).paddingTop, body: getComputedStyle(td).paddingTop };
      })()
    JS

    assert_equal "12px", padding["header"]
    assert_equal "6px", padding["body"]
  end
end
