# frozen_string_literal: true

require "application_system_test_case"

# The rendered ghost, not the class list.
#
# design.md: every table row action is the tertiary ghost - slate at rest, a leading icon, and a
# rose hover for the destructive one. Before this the same three actions were written six ways
# across nine tables, and Delete was red at rest in five of them, so these assert the properties
# that made it inconsistent: the resting colour, the icon, and the height.
class RowActionsTest < ApplicationSystemTestCase
  # 32px at lg, 44px where the finger is. GHOST_BASE is min-h-11 lg:min-h-8.
  DESKTOP_HEIGHT = 32
  TOUCH_HEIGHT = 44

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

  def row_action_boxes
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("tbody tr td:last-child a, tbody tr td:last-child button"))
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

    assert_operator actions.size, :>=, 3, "expected View / Edit / Delete on the school years row"

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

  test "a row action is 32px on a desktop and 44px on a phone" do
    sign_in(create(:admin))
    create(:school_year)

    in_chromebook_viewport do
      visit admin_school_years_path
      heights = row_action_boxes.pluck("height")

      assert_not_empty heights
      heights.each do |height|
        assert_in_delta DESKTOP_HEIGHT, height, 2,
                        "a desktop row action measured #{height}px; the ghost recedes from the " \
                        "40px primary button rather than matching or exceeding it"
      end
    end

    in_phone_viewport do
      visit admin_school_years_path
      heights = row_action_boxes.pluck("height")

      assert_not_empty heights
      heights.each do |height|
        assert_operator height, :>=, TOUCH_HEIGHT - 2,
                        "a row action measured #{height}px on a phone; 44px is the touch figure"
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
        action = find("a", text: label)

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
