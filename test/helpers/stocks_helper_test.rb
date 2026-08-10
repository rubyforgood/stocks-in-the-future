# frozen_string_literal: true

require "test_helper"

# The sentence that makes "2 of 3" mean something, and the one that used to address the wrong person.
class StocksHelperTest < ActionView::TestCase
  test "a student is told what the list is, in their own voice" do
    student = build(:student)

    assert_equal "Companies you can buy shares in right now.",
                 active_stocks_description(student)
  end

  test "a student is never told what Held by counts, because they have no such column" do
    assert_no_match(/Held by/, active_stocks_description(build(:student), investors: 5, classrooms: 2))
  end

  test "a teacher is addressed as someone who cannot buy, and told which students are counted" do
    note = active_stocks_description(build(:teacher), investors: 25, classrooms: 2)

    assert_match(/Companies your students can buy shares in right now\./, note)
    assert_match(/Held by counts owners in your classrooms - 25 students with a portfolio\./, note)
  end

  test "an admin's scope is stated as a number of classrooms, because 'every' is unbounded" do
    note = active_stocks_description(build(:admin), investors: 40, classrooms: 3)

    assert_match(/Held by counts owners across 3 classrooms - 40 students with a portfolio\./, note)
  end

  test "the counts are pluralised, so one classroom and one student read correctly" do
    note = active_stocks_description(build(:admin), investors: 1, classrooms: 1)

    assert_match(/across 1 classroom - 1 student with a portfolio\./, note)
  end

  test "nobody to count means no sentence, because there is no column to explain" do
    note = active_stocks_description(build(:teacher), investors: 0, classrooms: 1)

    assert_equal "Companies your students can buy shares in right now.", note
  end

  test "the market note is nil when a stock has no exchange, so nothing renders a stray separator" do
    assert_equal "NYSE", stock_market_note(build(:stock, stock_exchange: "NYSE"))
    assert_nil stock_market_note(build(:stock, stock_exchange: nil))
    assert_nil stock_market_note(build(:stock, stock_exchange: ""))
  end
end
