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
        insideCard: card.contains(primary),
        rowJustify: getComputedStyle(row).justifyContent,
        cardRadius: getComputedStyle(card).borderTopLeftRadius,
        cardBorder: getComputedStyle(card).borderTopWidth
      };
    })()
  JS

  def assert_leading_edge_actions(label)
    g = page.evaluate_script(GEOMETRY)

    assert_not_nil g, "#{label}: no submit or no card found"
    assert_not g["insideCard"], "#{label}: the actions are inside the card"
    assert_equal "rgba(0, 0, 0, 0)", g["rowBackground"],
                 "#{label}: the action row is tinted (#{g['rowBackground']}); it sits on the page"
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
end
