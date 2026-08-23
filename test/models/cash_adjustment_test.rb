# frozen_string_literal: true

require "test_helper"

# The unit-level counterpart to the request tests in admin/students_controller_test: what the object
# accepts, and what it writes when it does.
class CashAdjustmentTest < ActiveSupport::TestCase
  setup do
    @portfolio = create(:portfolio)
  end

  def adjustment(**overrides)
    defaults = { portfolio: @portfolio, transaction_type: "deposit", amount: "12.50", reason: "awards" }

    CashAdjustment.new(defaults.merge(overrides))
  end

  test "a complete adjustment is valid and writes integer cents" do
    subject = adjustment

    assert_predicate subject, :valid?
    assert subject.save

    written = @portfolio.portfolio_transactions.last

    assert_equal 1_250, written.amount_cents
    assert_equal "deposit", written.transaction_type
    assert_equal "awards", written.reason
  end

  # The whole reason this object exists. Every cent from $0.01 to $20.00 has to survive being typed as
  # dollars and read back as cents; `(amount.to_f * 100).to_i` fails 4,586 of the first 100,000, always
  # one low. A literal sample of the failures is in the request test; this is the property.
  test "every two-decimal amount parses to the exact number of cents" do
    wrong = (1..2_000).reject do |cents|
      adjustment(amount: format("%.2f", cents / 100.0)).amount_cents == cents
    end

    assert_empty wrong, "these typed amounts did not round trip: #{wrong.first(10).inspect}"
  end

  test "an amount that is not money is rejected rather than coerced" do
    ["abc", "", " ", "-50", "12.345", "1e3", "$12.50", "12,50", "99999999999"].each do |typed|
      subject = adjustment(amount: typed)

      assert_not subject.valid?, "#{typed.inspect} should be rejected"
      assert_includes subject.errors.attribute_names, :amount
    end
  end

  # "abc".to_f is 0.0, and 0 is not blank - so the check this replaces saved a $0.00 transaction and
  # reported success.
  test "an amount of zero moves nothing and is rejected" do
    ["0", "0.0", "0.00"].each do |typed|
      subject = adjustment(amount: typed)

      assert_not subject.valid?, "#{typed.inspect} should be rejected"
      assert_includes subject.errors.full_messages, "Amount must be more than zero"
    end
  end

  test "a direction and a reason are both required, and both are constrained to what the form offers" do
    assert_not adjustment(transaction_type: "").valid?
    assert_not adjustment(transaction_type: "credit").valid?
    assert_not adjustment(reason: "").valid?
    assert_not adjustment(reason: "not_a_reason").valid?
    # Deprecated on the model's own enum, and the picker offered it until now.
    assert_not adjustment(reason: "grade_earnings").valid?
    assert_not_includes CashAdjustment::REASONS, "grade_earnings"
  end

  # Only reachable by posting straight to the route, which is exactly why it must report rather than raise:
  # `belongs_to :portfolio` would fail the insert.
  test "an adjustment with no portfolio says so instead of raising" do
    subject = adjustment(portfolio: nil)

    assert_not subject.valid?
    assert_includes subject.errors.full_messages, "Portfolio must exist before money can move"
    assert_not subject.save
  end

  test "a blank description is stored as nil rather than an empty string" do
    assert adjustment(description: "  ").save

    assert_nil @portfolio.portfolio_transactions.last.description
  end

  test "nothing is written when the adjustment is invalid" do
    assert_no_difference("PortfolioTransaction.count") do
      assert_not adjustment(amount: "abc").save
    end
  end
end
