# frozen_string_literal: true

require "application_system_test_case"

# The rendered ghost, not the class list.
#
# design.md: every table row action is the tertiary ghost - slate at rest, a leading icon, and a
# rose hover for the destructive one. Before this the same three actions were written six ways
# across nine tables, and Delete was red at rest in five of them, so these assert the properties
# that made it inconsistent: the resting colour, the icon, and the height.
class RowActionsTest < ApplicationSystemTestCase
  # 32px at every width. GHOST_BASE is min-h-8: 44px is for bare tap targets, and a row action has
  # a visible label and about 80px of width.
  ROW_ACTION_HEIGHT = 32

  # Read the reference off the page rather than hard-coding a colour string. Tailwind v4 emits
  # oklch(), so slate-600 is "oklch(0.446 0.043 257.281)" and not the rgb() an earlier version of
  # this test expected - which says nothing about whether the ghost is the right colour.
  def slate_ink
    page.evaluate_script(<<~JS)
      (function () {
        const probe = document.createElement("span");
        probe.className = "text-slate-600";
        document.body.appendChild(probe);
        const colour = getComputedStyle(probe).color;
        probe.remove();
        return colour;
      })()
    JS
  end

  # Only the copy that is on screen. Below lg a row's actions are rendered twice - once in the trailing
  # cell, once inside the primary cell, which is the collapse that stops the table scrolling sideways at
  # 375px - and the trailing cell is `display: none` at that width. Measuring both reported a row action
  # 0px tall, which is not a spacing regression but a measurement of a hidden element.
  #
  # And scoped to the two containers that hold actions, rather than every link in the row. `tbody tr a`
  # stopped meaning "a row action" when the record's name became a link: this then measured that 17px
  # link as a 32px ghost with a missing icon, and reported it as two spacing failures.
  def row_action_boxes
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll(
             "td.table-actions-cell a, td.table-actions-cell button, " +
             "[data-testid='stacked-row-actions'] a, [data-testid='stacked-row-actions'] button"))
           .filter(function (el) { return el.getClientRects().length > 0; })
           .map(function (el) {
             const box = el.getBoundingClientRect();
             return {
               text: el.textContent.trim(),
               height: Math.round(box.height),
               colour: getComputedStyle(el).color,
               icons: el.querySelectorAll("svg").length
             };
           })
    JS
  end

  test "every row action is slate at rest and carries a leading icon" do
    sign_in(create(:admin))
    create(:school_year)

    visit admin_school_years_path

    actions = row_action_boxes
    slate = slate_ink

    # One, and it has been three. `View` went when the name in the primary cell became a link to the
    # record's page, and `Edit` went for the same reason once that page started editing in place - both
    # were a second control to one destination. What is left is Delete, which is something no link does.
    #
    # This is the row with the fewest actions in the admin, which is why the test uses it: the properties
    # below are about a single ghost, and asserting a count here only pins the floor.
    assert_operator actions.size, :>=, 1, "expected Delete on the school years row"

    actions.each do |action|
      assert_equal 1, action["icons"],
                   "#{action['text']} has #{action['icons']} icons; a row action is a ghost with " \
                   "exactly one leading glyph"
      assert_equal slate, action["colour"],
                   "#{action['text']} renders #{action['colour']} at rest. Both ghost variants " \
                   "are slate at rest and differ only on hover - a column of red Delete links " \
                   "is an always-on alarm"
    end
  end

  test "a row action is 32px at every width" do
    sign_in(create(:admin))
    create(:school_year)

    [method(:in_chromebook_viewport), method(:in_phone_viewport)].each do |viewport|
      viewport.call do
        visit admin_school_years_path
        heights = row_action_boxes.pluck("height")

        assert_not_empty heights
        heights.each do |height|
          assert_in_delta ROW_ACTION_HEIGHT, height, 2,
                          "a row action measured #{height}px; it recedes from the 40px primary " \
                          "button, and beside a 17px line of text a taller box reads as a slab"
        end
      end
    end
  end

  # The app side, not just admin. The classroom roster had its own treatment: three icon-only 32px
  # links whose only accessible name was a title attribute, tinted black / amber / red at rest.
  test "an app-side row action is the same ghost as an admin one" do
    classroom = create(:classroom)
    student = create(:student, :with_portfolio, classroom:)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in(teacher)

    visit classroom_path(classroom)

    within "##{dom_id(student)}" do
      ["Edit", "Reset password", "Delete"].each do |label|
        # `a, button`: a row action that navigates is a link and one that acts is a `button_to`.
        action = find("a, button", text: label)

        assert_equal 1, action.all("svg", visible: :all).size,
                     "#{label} on the roster should carry exactly one leading icon"
        assert_equal slate_ink, action.style("color")["color"],
                     "#{label} on the roster renders #{action.style('color')['color']} at rest"
      end
    end
  end

  # There is deliberately no test here for the rendered hover colour. Tailwind v4 emits hover:
  # utilities inside @media (hover:hover), and this headless Chromium reports (hover: none), so
  # :hover matches the element while the declaration never applies - measured: the Delete link is
  # slate at rest and still slate with the pointer over it and el.matches(":hover") true. No hover
  # state in this app can be verified from a system test. The declared contract is asserted in
  # test/helpers/button_helper_test.rb instead.
end
