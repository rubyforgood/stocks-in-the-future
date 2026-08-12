# frozen_string_literal: true

require "application_system_test_case"

# design.md: "Form actions anchor to the leading edge, never centred."
#
# The students#edit and #new pages did neither. Their submit and cancel sat in a
# `px-4 py-3 bg-slate-50 text-right` strip **inside** the card - reported as a grey background behind
# the buttons - and the admin side right-aligned its actions on the page background, so the product had
# three answers to one question. One shape now: on the page background below the card, aligned to the
# card's leading edge, primary first.
class FormActionsTest < ApplicationSystemTestCase
  GEOMETRY = <<~JS
    (function () {
      const form = document.querySelector("main form");
      const card = form.querySelector(".tw-card") || form.closest("main").querySelector(".tw-card");
      const primary = form.querySelector("input[type=submit], button[type=submit]");
      if (!primary || !card) return null;
      const row = primary.parentElement;
      const b = (el) => el.getBoundingClientRect();
      return {
        primaryLeft: Math.round(b(primary).left),
        cardLeft: Math.round(b(card).left),
        primaryHeight: Math.round(b(primary).height),
        rowBackground: getComputedStyle(row).backgroundColor,
        rowBorderTop: getComputedStyle(row).borderTopWidth,
        // The body, not main: admin's main has no background of its own, so comparing against it read the
        // row as contrasting with transparent.
        pageBackground: getComputedStyle(document.body).backgroundColor,
        rowPosition: getComputedStyle(row).position,
        insideCard: card.contains(primary),
        rowJustify: getComputedStyle(row).justifyContent,
        cardRadius: getComputedStyle(card).borderTopLeftRadius,
        cardBorder: getComputedStyle(card).borderTopWidth
      };
    })()
  JS

  # Dirties the form the way a person does. On an **update** form the action row is hidden until there is
  # something to save - a Save button on a page you are only reading is friction, which is what Polaris's
  # ContextualSaveBar avoids - so every measurement below needs the row on screen first.
  def dirty_the_form
    page.execute_script(<<~JS)
      (function () {
        const field = document.querySelector("main form input[type=text], main form input[type=email], " +
                                             "main form textarea, main form select");
        if (field) field.dispatchEvent(new Event("input", { bubbles: true }));
      })()
    JS
  end

  def assert_leading_edge_actions(label)
    updates = page.evaluate_script(%(!!document.querySelector("main form input[name='_method']")))

    if updates
      assert_equal "none",
                   page.evaluate_script("getComputedStyle(document.querySelector('main .tw-form-actions')).display"),
                   "#{label}: the action row is on screen before anything has changed"
    end

    dirty_the_form
    g = page.evaluate_script(GEOMETRY)

    assert_not_nil g, "#{label}: no submit or no card found"
    assert_not g["insideCard"], "#{label}: the actions are inside the card"
    # **The row may not be a *contrasting* band, which is what this rule was protecting** - the reported
    # defect was buttons on a grey strip inside the card. It is now `sticky bottom-0`, because a form longer
    # than the viewport put its submit at y=1094 of 625 on admin/schools#edit and no amount of shortening the
    # fields fixed that. A sticky row has to be opaque or the page scrolls visibly through the buttons, so
    # the test is that its background is the **page's own colour**: it looks like the page when it is not
    # overlapping anything, and hides what passes under it when it is.
    assert_includes ["rgba(0, 0, 0, 0)", g["pageBackground"]], g["rowBackground"],
                    "#{label}: the action row is #{g['rowBackground']} against a page of " \
                    "#{g['pageBackground']} - it may match the page or be transparent, not contrast"
    # Pinned, now that there is something to save. It cannot be pinned always - reported twice, once for the
    # rule it drew and once for hovering over a page whose only field is a name nobody was editing - and it
    # cannot be static either: measured, the submit would sit at y=3298 on admin/stocks#edit against a 625px
    # viewport. Polaris, Shopify admin and Stripe all reveal the save on change.
    # Both kinds pin once dirty - a create form needs it just as much, with students#new's submit at y=1043.
    # What differs is only whether the row starts hidden, which is asserted above.
    assert_equal "sticky", g["rowPosition"],
                 "#{label}: the action row is #{g['rowPosition']} with unsaved changes on screen"

    # **And no rule.** This carried a `border-t` for one commit, on nine forms, and design.md's Dividers
    # section rules it out by name: "no extra dividers anywhere", followed by an exhaustive list of the four
    # that stay - none of which is a form's action row. It was also a hairline against nothing on every form
    # shorter than the viewport. The opaque background is what hides scrolling content; the line added a
    # treatment that exists nowhere else in the app.
    assert_equal "0px", g["rowBorderTop"],
                 "#{label}: the action row draws a #{g['rowBorderTop']} rule above it, which nothing else " \
                 "in the app does - see design.md's Dividers section"
    assert_in_delta g["cardLeft"], g["primaryLeft"], 1,
                    "#{label}: the primary is at #{g['primaryLeft']}px against a card edge of " \
                    "#{g['cardLeft']}px - actions anchor to the leading edge"
    assert_not_equal "flex-end", g["rowJustify"], "#{label}: the action row is right-aligned"
    assert_not_equal "center", g["rowJustify"], "#{label}: the action row is centred"
    # design.md's height token, and the same one the page header's buttons use.
    assert_in_delta 40, g["primaryHeight"], 2, "#{label}: the primary is #{g['primaryHeight']}px tall"
    # The card is the token surface, not a hand-rolled one: this was `lg:rounded-md` with no border.
    assert_equal "16px", g["cardRadius"], "#{label}: the card is not the rounded-2xl token"
    assert_equal "1px", g["cardBorder"], "#{label}: the card has no border"
  end

  test "the teacher's student forms put their actions on the leading edge" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:, name: "Ada Lovelace")
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    visit new_classroom_student_path(classroom)
    assert_leading_edge_actions("students#new")

    visit edit_classroom_student_path(classroom, student)
    assert_leading_edge_actions("students#edit")

    # Primary first at the leading edge - the order follows the alignment, which is why the two cannot
    # be mixed. Polaris and Stripe put cancel first, but they right-align.
    order = page.evaluate_script(<<~JS)
      (function () {
        const row = document.querySelector("main form input[type=submit]").parentElement;
        return Array.from(row.children).map(function (el) {
          return (el.value || el.textContent || "").trim();
        });
      })()
    JS

    assert_equal ["Update student", "Cancel"], order
  end

  # The classroom form, both pages, both roles. It was the last form in the app on none of this: no card
  # at all, `lg:w-2/3` instead of a measure, its own error-summary shape, and two `tw-btn-secondary` nav
  # links under the form instead of a cancel beside the submit.
  test "the classroom form puts its actions on the leading edge" do
    classroom = create(:classroom, :with_trading, grades: [create(:grade, level: 5, name: "5th Grade")])
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    visit edit_classroom_path(classroom)
    assert_leading_edge_actions("classrooms#edit as a teacher")

    order = page.evaluate_script(<<~JS)
      (function () {
        const row = document.querySelector("main form input[type=submit]").parentElement;
        return Array.from(row.children).map(function (el) {
          return (el.value || el.textContent || "").trim();
        });
      })()
    JS

    assert_equal ["Update classroom", "Cancel"], order

    # And the pair of navigation buttons that used to sit below the form is gone.
    assert_no_link "Back to classrooms"
    assert_no_link "View classroom"

    # #new is admin-only - ClassroomPolicy#new? is `user.admin?` - so a teacher visiting it is redirected
    # and there is no form to measure. Checked as an admin, which is who can reach it.
    sign_in create(:admin)
    visit new_classroom_path
    assert_leading_edge_actions("classrooms#new as an admin")

    created = page.evaluate_script(<<~JS)
      (function () {
        const row = document.querySelector("main form input[type=submit]").parentElement;
        return Array.from(row.children).map(function (el) {
          return (el.value || el.textContent || "").trim();
        });
      })()
    JS

    assert_equal ["Create classroom", "Cancel"], created
  end

  # A group of checkboxes is a fieldset with a legend. `form.label :grade_ids` emitted
  # `for="classroom_grade_ids"` and nothing had that id, so the group had no accessible name - and all
  # four checkboxes plus the hidden field shared `id="classroom_grade_ids_"`, which is invalid.
  test "the classroom form's option groups are named, and its ids are unique" do
    classroom = create(:classroom, :with_trading, grades: [create(:grade, level: 5, name: "5th Grade")])
    sign_in create(:admin)

    visit edit_classroom_path(classroom)

    assert_selector "fieldset legend", text: "Grades"
    assert_selector "fieldset legend", text: "Teachers"

    problems = page.evaluate_script(<<~JS)
      (function () {
        const seen = {}, dupes = [], orphans = [];
        document.querySelectorAll("main [id]").forEach(function (el) {
          if (seen[el.id] && dupes.indexOf(el.id) < 0) dupes.push(el.id);
          seen[el.id] = true;
        });
        document.querySelectorAll("main label[for]").forEach(function (l) {
          if (!document.getElementById(l.getAttribute("for"))) orphans.push(l.getAttribute("for"));
        });
        return { dupes: dupes, orphans: orphans };
      })()
    JS

    assert_empty problems["dupes"], "duplicate ids: #{problems['dupes'].join(', ')}"
    assert_empty problems["orphans"], "labels pointing at no element: #{problems['orphans'].join(', ')}"
  end

  # Four grades and, seeded, one teacher - so both option lists were `max-h-60 overflow-y-auto` boxes
  # around content that cannot scroll, with a slate-50 fill inside what is now a card.
  test "the classroom form has no scrolling sub-panels" do
    classroom = create(:classroom, :with_trading, grades: [create(:grade, level: 5, name: "5th Grade")])
    sign_in create(:admin)

    visit edit_classroom_path(classroom)

    scrollers = page.evaluate_script(<<~JS)
      (function () {
        return Array.from(document.querySelectorAll("main form *")).filter(function (el) {
          const cs = getComputedStyle(el);
          return (cs.overflowY === "auto" || cs.overflowY === "scroll");
        }).length;
      })()
    JS

    assert_equal 0, scrollers
  end

  test "the admin forms put their actions on the leading edge too" do
    school = create(:school)
    school_year = create(:school_year, school:, year: create(:year))
    create(:classroom, :with_trading, school_year:)
    sign_in create(:admin)

    { "admin/schools#new" => new_admin_school_path,
      "admin/stocks#new" => new_admin_stock_path,
      "admin/announcements#new" => new_admin_announcement_path }.each do |label, path|
      visit path
      assert_leading_edge_actions(label)
    end
  end

  # And at 375px, where a right-aligned pair used to push the cancel to the edge of a 343px viewport.
  test "the actions stay on the leading edge at 375px" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    in_phone_viewport do
      visit new_classroom_student_path(classroom)
      assert_leading_edge_actions("students#new at 375px")
    end
  end

  # A group's hint goes **under its subheader, before the options** - design.md: "hint text under the group's
  # subheader ... not floating between two field groups", because a hint between groups is ambiguous about
  # which one it modifies. Both of the classroom form's groups had theirs below the options, which put the
  # instruction after the decision it governs.
  test "a field group's hint sits between its legend and its options" do
    create(:school)
    # The grades group renders nothing without them, and a group with no options cannot show hint order.
    (Classroom::MIN_GRADE..Classroom::MAX_GRADE).each { |n| create(:grade, level: n, name: "#{n}th Grade") }
    create(:teacher, name: "Terry Teacher")
    sign_in create(:admin)

    visit new_classroom_path

    order = page.evaluate_script(<<~JS)
      (function () {
        return Array.from(document.querySelectorAll("main form fieldset")).map(function (fs) {
          const y = (el) => el.getBoundingClientRect().top + window.scrollY;
          const hint = fs.querySelector("p");
          const option = fs.querySelector("input[type=checkbox]");
          return { group: fs.querySelector("legend").textContent.replace("*", "").trim(),
                   hintBeforeOptions: !!hint && !!option && y(hint) < y(option) };
        });
      })()
    JS

    assert_equal %w[Grades Teachers], order.pluck("group")
    order.each do |group|
      assert group["hintBeforeOptions"],
             "#{group['group']}: the hint is below its options, so it explains a choice already made"
    end
  end

  # Selecting a teacher: a checkbox list, which is what a short known set takes, and **no avatar**. A 32px
  # disc containing one letter identifies nobody - two teachers whose names start with T get the same disc -
  # while taking the widest column in the row. The name and the email identify; the email disambiguates.
  test "a teacher is chosen by name and email, not by an initial in a disc" do
    create(:school)
    create(:teacher, name: "Terry Teacher", email: "terry@example.com")
    sign_in create(:admin)

    visit new_classroom_path

    row = page.evaluate_script(<<~JS)
      (function () {
        const label = document.querySelector("input[id^='classroom_teacher_ids_']").closest("label");
        const centre = (el) => { const b = el.getBoundingClientRect(); return b.top + b.height / 2; };
        const discs = Array.from(label.querySelectorAll("span")).filter(function (s) {
          return parseFloat(getComputedStyle(s).borderRadius) > 12;
        });
        return { discs: discs.length,
                 text: label.textContent.replace(/\s+/g, " ").trim(),
                 offset: Math.round(centre(label.querySelector("input")) -
                                    centre(label.querySelector("span.font-medium"))) };
      })()
    JS

    assert_equal 0, row["discs"], "the teacher row still carries an avatar disc"
    assert_includes row["text"], "Terry Teacher"
    assert_includes row["text"], "terry@example.com"
    # mt-0.5 puts the 16px box's centre on the name's first line, not its top edge - design.md's own test.
    assert_in_delta 0, row["offset"], 1
  end

  # Trading is a behaviour with a default, not part of what the classroom is, and it is the one setting with
  # its own control on the classroom page - so it comes last, after identity and access.
  test "enable trading comes last, with its hint under its own label" do
    create(:school)
    create(:teacher)
    sign_in create(:admin)

    visit new_classroom_path

    layout = page.evaluate_script(<<~JS)
      (function () {
        const y = (el) => el.getBoundingClientRect().top + window.scrollY;
        const box = document.querySelector("#classroom_trading_enabled");
        const wrapper = box.closest("div");
        const label = box.closest("label").querySelector("span");
        const hint = wrapper.querySelector("p");
        const groups = Array.from(document.querySelectorAll("main form fieldset"));
        const textLeft = function (el) {
          const w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
          while (w.nextNode()) {
            if (w.currentNode.textContent.trim()) {
              const r = document.createRange();
              r.selectNodeContents(w.currentNode);
              const rect = r.getClientRects()[0];
              if (rect) return Math.round(rect.left);
            }
          }
          return null;
        };
        return { afterEveryGroup: groups.every(function (g) { return y(wrapper) > y(g); }),
                 labelX: textLeft(label), hintX: textLeft(hint),
                 checkboxX: Math.round(box.getBoundingClientRect().left) };
      })()
    JS

    assert layout["afterEveryGroup"], "enable trading is not the last field in the form"
    assert_equal layout["labelX"], layout["hintX"],
                 "the hint starts under the checkbox rather than under its label's text"
    assert_operator layout["hintX"], :>, layout["checkboxX"]
  end

  # Every control in a form shares one left edge.
  #
  # Reported as the teacher checkbox looking misaligned, and measuring both axes found where: vertically all
  # six checkboxes were already 0.5px off their own label's first line, but the grades and teachers rows
  # carried `px-2` for their hover band, so their boxes sat at 518 while the inputs above and the trading
  # checkbox below sat at 510. A checkbox 8px right of the field it follows reads as the checkbox being
  # wrong, which is how it was reported.
  #
  # GOV.UK's checkbox item has no left padding for exactly this reason; an indent is reserved for a nested or
  # dependent option. The alternative - keeping the padding and pulling the row back with a negative margin -
  # takes the hover fill with it, which this codebase records three times as the wrong fix.
  test "every control on the classroom form starts at the same left edge" do
    create(:school)
    (Classroom::MIN_GRADE..Classroom::MAX_GRADE).each { |n| create(:grade, level: n, name: "#{n}th Grade") }
    create(:teacher, name: "Terry Teacher")
    sign_in create(:admin)

    visit new_classroom_path

    edges = page.evaluate_script(<<~JS)
      (function () {
        const left = (el) => Math.round(el.getBoundingClientRect().left);
        const form = document.querySelector("main form");
        const gutter = left(form.querySelector("input.tw-input-primary"));
        const strays = [];

        form.querySelectorAll("legend").forEach(function (el) {
          if (left(el) !== gutter) strays.push("legend " + el.textContent.trim() + " at " + left(el));
        });

        // The first checkbox of each group only: a grid's later columns are legitimately indented.
        const seen = {};
        form.querySelectorAll("input[type=checkbox]").forEach(function (box) {
          const group = box.closest("fieldset") || form;
          const key = group.querySelector("legend") ? group.querySelector("legend").textContent.trim() : "form";
          if (seen[key]) return;
          seen[key] = true;
          if (left(box) !== gutter) {
            strays.push("first checkbox of " + key + " at " + left(box) + " against a gutter of " + gutter);
          }
        });

        return { gutter: gutter, strays: strays };
      })()
    JS

    assert_empty edges["strays"],
                 "these do not start on the form's gutter (#{edges['gutter']}px): #{edges['strays'].join(', ')}"
  end

  # And the other axis, which was already right and should stay so: a checkbox sits on its label's first
  # line - centred against a single-line label, nudged to the first line beside a two-line one. Both
  # mechanisms are correct and the measurement is the same; asserting the outcome rather than the class is
  # what lets them differ.
  test "every checkbox sits on its own label's first line" do
    create(:school)
    (Classroom::MIN_GRADE..Classroom::MAX_GRADE).each { |n| create(:grade, level: n, name: "#{n}th Grade") }
    create(:teacher, name: "Terry Teacher")
    sign_in create(:admin)

    visit new_classroom_path

    offsets = page.evaluate_script(<<~JS)
      (function () {
        const firstLine = function (el) {
          const w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
          while (w.nextNode()) {
            if (w.currentNode.textContent.trim()) {
              const r = document.createRange();
              r.selectNodeContents(w.currentNode);
              const rect = r.getClientRects()[0];
              if (rect) return rect;
            }
          }
          return null;
        };
        const out = [];
        document.querySelectorAll("main form input[type=checkbox]").forEach(function (box) {
          const label = box.closest("label");
          if (!label) return;
          const text = Array.from(label.querySelectorAll("span")).find(s => s.textContent.trim()) || label;
          const line = firstLine(text);
          if (!line) return;
          const b = box.getBoundingClientRect();
          out.push({ label: text.textContent.replace(/\s+/g, " ").trim().slice(0, 18),
                     off: Math.round(((b.top + b.height / 2) - (line.top + line.height / 2)) * 10) / 10 });
        });
        return out;
      })()
    JS

    assert_operator offsets.size, :>=, 5
    offsets.each do |row|
      assert_in_delta 0, row["off"], 1,
                      "\"#{row['label']}\" is #{row['off']}px off its label's first line"
    end
  end

  # One vertical rhythm above the card, with or without an error summary.
  #
  # Asked whether the gap between the header's helper text and the top of the card was consistent. Without a
  # summary it was - 24px on all three form pages - but the classroom card carried an inert `mt-4`: adjacent
  # margins collapse to the larger, and the header's own `mb-6` is bigger, so it did nothing until a summary
  # appeared between the two and gave that state 16px. On the student forms the summary sat **flush against
  # the card at 0px**. Three forms, three different gaps in the error state.
  #
  # The summary spaces itself now, which is the only place that can be right for all three.
  test "the gap above the card is the same on every form, with errors and without" do
    classroom = create(
      :classroom, :with_trading,
      name: "Rhythm Class", grades: [create(:grade, level: 5, name: "5th Grade")]
    )
    student = create(:student, :with_portfolio, classroom:, name: "Ada Lovelace")
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    gap = <<~JS
      (function () {
        const main = document.querySelector("main");
        const card = main.querySelector(".tw-card");
        const summary = main.querySelector("[data-testid='form-errors']");
        const above = summary || Array.from(main.querySelectorAll("p")).find(function (p) {
          return p.getBoundingClientRect().bottom <= card.getBoundingClientRect().top;
        });
        return Math.round(card.getBoundingClientRect().top - above.getBoundingClientRect().bottom);
      })()
    JS

    { "students#new" => new_classroom_student_path(classroom),
      "students#edit" => edit_classroom_student_path(classroom, student),
      "classrooms#edit" => edit_classroom_path(classroom) }.each do |label, path|
      visit path

      assert_equal 24, page.evaluate_script(gap), "#{label}: the gap above the card is not 24px"
    end

    # And the error state, where the three forms used to disagree by 24px.
    visit edit_classroom_path(classroom)
    fill_in "Name", with: ""
    click_on "Update classroom"
    assert_selector "[data-testid='form-errors']"

    assert_equal 24, page.evaluate_script(gap),
                 "with a summary showing, the gap above the card is not 24px"
  end

  # The other half of the hidden action row, and the half that was wrong: a form which has just been
  # **rejected** must keep its Save button. Measured before the fix: blanking the name on a student's record
  # page and pressing Update re-rendered the page with "1 error stopped this student being saved" and a
  # `display: none` action row, so the only way to try again was to type in a field.
  test "a rejected form keeps its save button, and the form beside it does not gain one" do
    student = create(:student, :with_portfolio, name: "Ada Lovelace")
    student.reload
    sign_in create(:admin)

    row_display = <<~JS
      (function () {
        const form = document.querySelector("main form[action='%s']");
        const row = form.querySelector(".tw-form-actions");
        return row ? getComputedStyle(row).display : "no row";
      })()
    JS

    visit admin_student_path(student)

    assert_equal "none", page.evaluate_script(row_display % admin_student_path(student)),
                 "the action row is on screen before anything has changed"

    fill_in "Full name", with: ""
    click_on "Update student"

    assert_selector "[data-testid='form-errors']"
    assert_equal "flex", page.evaluate_script(row_display % admin_student_path(student)),
                 "the rejected form has no way to submit again"

    # A rejected transaction must not un-hide the account form: that form is still clean. The form is a
    # disclosure now, so it has to be opened before its submit exists to click - which is also why the
    # summary reads "Add a transaction" and the submit "Add transaction", rather than both the same.
    visit admin_student_path(student)
    find("[data-testid='add-transaction-disclosure'] summary").click
    click_on "Add transaction"

    assert_selector "[data-testid='form-errors']"
    assert_equal "none", page.evaluate_script(row_display % admin_student_path(student)),
                 "a rejected transaction revealed the account form's save row"
  end

  # The money form is collapsed, because it was 728px of a 2958px page - a quarter of the scroll - held open
  # for a task an administrator does occasionally. Measured after: the page is 1914px, and opening the form
  # takes it to 2634px, which is the point of a disclosure.
  #
  # A `<details>`, so this also asserts the thing a hand-rolled panel gets wrong: what a **closed** form does
  # to the keyboard. `getBoundingClientRect()` still reports 44px for a field inside a closed details in
  # Chrome - the geometry from before it closed - so the honest instruments are `checkVisibility()` and
  # whether `focus()` takes.
  test "the money form is closed until asked for, and unreachable while it is" do
    student = create(:student, :with_portfolio, name: "Ada Lovelace")
    student.reload
    sign_in create(:admin)

    visit admin_student_path(student)

    state = <<~JS
      (function () {
        const details = document.querySelector("[data-testid='add-transaction-disclosure']");
        const amount = document.querySelector("[name='cash_adjustment[amount]']");
        return {
          open: details.open,
          pageHeight: Math.round(document.body.scrollHeight),
          amountVisible: amount.checkVisibility({ contentVisibilityAuto: true }),
          amountFocusable: (function () { amount.focus(); return document.activeElement === amount; })()
        };
      })()
    JS

    closed = page.evaluate_script(state)

    assert_equal false, closed["open"], "the money form is open before anybody asked for it"
    assert_equal false, closed["amountVisible"], "a closed form's field is still visible"
    assert_equal false, closed["amountFocusable"], "tab reaches a field inside the closed form"

    find("[data-testid='add-transaction-disclosure'] summary").click
    opened = page.evaluate_script(state)

    assert_equal true, opened["open"]
    assert_equal true, opened["amountVisible"]
    assert_operator opened["pageHeight"], :>, closed["pageHeight"] + 400,
                    "opening the form did not add the form's height, so it was never really closed"

    # A rejected submit has to come back **open**, with what was typed. The panel's state is a server-rendered
    # attribute for exactly this reason.
    fill_in "Amount", with: "50"
    click_on "Add transaction"

    assert_selector "[data-testid='form-errors']"
    assert_selector "[data-testid='add-transaction-disclosure'][open]"
    assert_equal "50", find("[name='cash_adjustment[amount]']").value
  end

  # The description says something the reader cannot already see. "You can add students once it exists" spent
  # itself on the obvious next step; the four grade books are the part nobody would guess.
  test "the new classroom page says what creating one does" do
    create(:school)
    sign_in create(:admin)

    visit new_classroom_path

    assert_text "Creating it adds a grade book for each quarter of the school year."
    assert_no_text "You can add students once it exists"
  end
end
