# frozen_string_literal: true

require "test_helper"

# components/ui/_empty_state has two sizes and the choice is not cosmetic: the centred
# py-12 treatment inside a small dashboard card made a card with nothing to say the tallest
# thing on the home page. Page and table level keep the large one; section level is compact.
class EmptyStateScaleTest < ActionDispatch::IntegrationTest
  test "the announcements empty state is compact, and the others are not" do
    sign_in(create(:student, :with_portfolio))
    get root_path

    assert_response :success
    body = response.parsed_body

    card = body.css("section.tw-card").find { |s| s.text.include?("Announcements") }
    assert_not_nil card, "expected an Announcements card"

    # Compact: no 48px icon tile, no py-12 block.
    assert_empty card.css(".h-12.w-12"), "announcements still renders the 48px icon tile"
    assert_empty card.css(".py-12"), "announcements still renders the py-12 centred block"
    assert_includes card.text, "No announcements yet"
  end

  test "a page-level empty state keeps the large treatment" do
    classroom = create(:classroom)
    teacher = create(:teacher)
    teacher.classrooms << classroom
    sign_in(teacher)

    get classroom_grade_book_path(classroom, classroom.grade_books.first)

    assert_response :success
    assert_select ".h-12.w-12", minimum: 1
    assert_select ".py-12", minimum: 1
  end
end
