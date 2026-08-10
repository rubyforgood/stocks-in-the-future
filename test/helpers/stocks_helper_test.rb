# frozen_string_literal: true

require "test_helper"

# The sentence that makes "2 of 3" mean something, and the one that used to address the wrong person.
class StocksHelperTest < ActionView::TestCase
  test "a student is told what the list is, in their own voice" do
    assert_equal "Companies you can buy shares in right now.",
                 active_stocks_description(build(:student))
  end

  test "a student is never told what Held by counts, because they have no such column" do
    assert_no_match(/Held by/, active_stocks_description(build(:student), students: 25))
  end

  test "a teacher is addressed as someone who cannot buy, and told whose figure it is" do
    note = active_stocks_description(build(:teacher), students: 25)

    assert_match(/Companies your students can buy shares in right now\./, note)
    assert_match(/Held by shows how many of your students own each one\./, note)
  end

  test "an admin is told the figure spans every classroom" do
    note = active_stocks_description(build(:admin), students: 40)

    assert_match(/Held by shows how many students own each one, across every classroom\./, note)
  end

  test "the sentence carries no counts, so it cannot read wrongly at one" do
    [1, 2, 40].each do |n|
      note = active_stocks_description(build(:teacher), students: n)

      assert_no_match(/\d/, note, "the scope sentence states a number, which has to be pluralised")
    end
  end

  test "nobody to count means no sentence, because there is no column to explain" do
    note = active_stocks_description(build(:teacher), students: 0)

    assert_equal "Companies your students can buy shares in right now.", note
  end

  test "the market note is nil when a stock has no exchange, so nothing renders a stray separator" do
    assert_equal "NYSE", stock_market_note(build(:stock, stock_exchange: "NYSE"))
    assert_nil stock_market_note(build(:stock, stock_exchange: nil))
    assert_nil stock_market_note(build(:stock, stock_exchange: ""))
  end
end
