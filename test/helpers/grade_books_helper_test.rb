# frozen_string_literal: true

require "test_helper"

# The status wording, which is the whole reason this helper exists. Asserted here rather than only
# through a page, because two views render it and the point of centralising it was that they cannot
# drift - a system test on one of them would not notice the other going stale.
class GradeBooksHelperTest < ActionView::TestCase
  include GradeBooksHelper

  test "every status has a label, and none of them is the enum's own word" do
    GradeBook.statuses.each_key do |status|
      book = build(:grade_book, status: status)
      label = grade_book_status(book)[:label]

      assert_predicate label, :present?
      assert_not_equal status.capitalize, label,
                       "#{status} still prints the raw enum value"
    end
  end

  # "Draft" is the word every other product uses for unsaved work, and this page autosaves next to a
  # Save button. It was read as "the grades have not saved", which is what the label must not permit.
  test "no label can be read as save state" do
    forbidden = %w[draft saved saving unsaved]

    GradeBook.statuses.each_key do |status|
      label = grade_book_status(build(:grade_book, status: status))[:label]

      forbidden.each do |word|
        assert_not_includes label.downcase, word, "#{status} reads as save state: #{label}"
      end
    end
  end

  test "the labels are the finalize lifecycle, in the page's own verb" do
    assert_equal "Not finalized", grade_book_status(build(:grade_book, status: :draft))[:label]
    assert_equal "Finalized", grade_book_status(build(:grade_book, status: :completed))[:label]
    # A progress word on purpose: finalize sets verified and distributes in the same request, so a
    # book resting here is one where distribution raised part way, not a state anyone chose.
    assert_equal "Finalizing", grade_book_status(build(:grade_book, status: :verified))[:label]
  end

  test "tone never carries the meaning alone" do
    tones = GradeBook.statuses.each_key.map { grade_book_status(build(:grade_book, status: it))[:tone] }

    assert_equal tones.size, tones.uniq.size, "two states share a tone, so the pill needs its words"
  end

  test "an unknown status still renders something readable" do
    book = build(:grade_book)
    book.define_singleton_method(:status) { "archived" }

    assert_equal "Archived", grade_book_status(book)[:label]
  end
end
