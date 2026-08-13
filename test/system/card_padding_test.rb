# frozen_string_literal: true

require "application_system_test_case"

# A card's padding is its interior gutter, and nothing inside adds to it.
#
# Reported as "too much padding on the bottom of the new teacher card", and it was every form card in the
# admin except one: **21px above the first field and 45px below the last**. No template asks for that.
# `Ui::FormBuilder` wraps every field in `mb-6`, which is the rhythm *between* fields, and the last one's
# 24px landed inside the card's 20px padding - the same shape as the header seam design.md already records,
# two spacings stacking where one was intended.
#
# This asserts the rendered box rather than the class list, because the class list says `p-5` on every one
# of them and always did.
class CardPaddingTest < ApplicationSystemTestCase
  # 20px of padding plus the card's 1px border, measured from the border box.
  EDGE = 21
  TOLERANCE = 2

  # The fix is a CSS chain of `:last-child` selectors, so a form that nests its fields deeper than the
  # chain reaches would quietly regain the gap. That is what this catches, and it is why the test walks
  # every form rather than the one that was reported.
  def gaps
    page.evaluate_script(<<~JS)
      (function () {
        const card = document.querySelector("main .tw-card");
        if (!card) return null;
        const cb = card.getBoundingClientRect();
        const body = card.matches("[class*='p-5']") ? card : card.querySelector(":scope > [class*='p-5']");
        if (!body) return null;
        const kids = Array.from(body.children).filter(function (k) { return k.getClientRects().length > 0; });
        if (!kids.length) return null;
        const first = kids[0].getBoundingClientRect();
        const last = kids[kids.length - 1].getBoundingClientRect();
        return { top: Math.round(first.top - cb.top), bottom: Math.round(cb.bottom - last.bottom) };
      })()
    JS
  end

  test "every admin form card is padded equally top and bottom" do
    sign_in(create(:admin))
    classroom = create(:classroom)
    create(:student, classroom:)
    create(:stock)
    create(:school)

    { "teachers" => new_admin_teacher_path,
      "students" => new_admin_student_path,
      "schools" => new_admin_school_path,
      "stocks" => new_admin_stock_path,
      "classrooms" => new_admin_classroom_path,
      "school years" => new_admin_school_year_path,
      "announcements" => new_admin_announcement_path,
      "users" => new_admin_user_path,
      "transactions" => new_admin_portfolio_transaction_path }.each do |name, path|
      visit path
      measured = gaps

      assert measured, "#{name}: no padded card body to measure"
      assert_in_delta EDGE, measured["top"], TOLERANCE,
                      "#{name}: #{measured['top']}px above the first field, expected #{EDGE}"
      assert_in_delta EDGE, measured["bottom"], TOLERANCE,
                      "#{name}: #{measured['bottom']}px below the last field against #{measured['top']}px " \
                      "above the first - a field's own mb-6 is stacking on the card's padding"
    end
  end
end
