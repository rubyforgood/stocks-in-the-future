# frozen_string_literal: true

require "test_helper"

# The dismissal is a timestamp compared against the classroom's, not a boolean, and these are the
# cases that distinguishes. A mute button passes the first two and fails the third.
class PortfolioTradingOffNoticeTest < ActiveSupport::TestCase
  def student_in(classroom)
    create(:student, :with_portfolio, classroom:).reload
  end

  test "no notice while trading is on" do
    student = student_in(create(:classroom, :with_trading))

    assert_not student.portfolio.reload.trading_off_notice?
  end

  test "a notice while trading is off and undismissed" do
    student = student_in(create(:classroom, trading_enabled: false))

    assert student.portfolio.trading_off_notice?
  end

  test "dismissing hides it" do
    student = student_in(create(:classroom, trading_enabled: false))
    student.dismiss!(Dismissal::TRADING_OFF)

    assert_not student.portfolio.reload.trading_off_notice?
  end

  # The case a boolean cannot express, and the reason this column is a timestamp: a student who
  # dismissed last term's switch-off is entitled to see this term's.
  test "it returns when trading is switched off again" do
    classroom = create(:classroom, trading_enabled: false)
    student = student_in(classroom)
    student.dismiss!(Dismissal::TRADING_OFF)

    assert_not student.portfolio.reload.trading_off_notice?

    classroom.update!(trading_enabled: true)

    assert_nil classroom.reload.trading_disabled_at,
               "switching trading on must clear the onset, or the next switch-off reports the first date"

    travel 1.minute do
      classroom.update!(trading_enabled: false)

      assert student.portfolio.reload.trading_off_notice?,
             "a dismissal must not survive a later switch-off"
    end
  end

  # Not backfilled on purpose, so existing rows have no onset. A dismissal is honoured rather than
  # ignored, and the next real toggle makes the comparison exact.
  test "a dismissal is honoured when the onset is unknown" do
    classroom = create(:classroom, trading_enabled: false)
    student = student_in(classroom)
    # update_column deliberately: the before_save is what stamps this, so any ordinary save would put
    # the value straight back. A row with no onset is precisely what not backfilling leaves behind, and
    # there is no other way to construct one.
    classroom.update_column(:trading_disabled_at, nil) # rubocop:disable Rails/SkipsModelValidations
    student.dismiss!(Dismissal::TRADING_OFF)

    assert_not student.portfolio.reload.trading_off_notice?
  end

  # The case the suite missed. Every other test here enables trading before disabling it, and enabling
  # nils the onset - so `trading_disabled_at ||= Time.current` was never asked to overwrite a stale
  # value, and it did not. A row can sit in that state for real: any write that skips callbacks leaves
  # trading on with a date still set, and so does a row that predates the column.
  #
  # Without the fix the onset stays in the past, a dismissal made in between outranks it, and the
  # callout never returns - which is the whole failure the timestamp exists to prevent.
  test "switching off overwrites a stale onset rather than keeping it" do
    classroom = create(:classroom, trading_enabled: false)
    student = student_in(classroom)
    stale = 1.week.ago

    # rubocop:disable Rails/SkipsModelValidations
    classroom.update_column(:trading_enabled, true)
    classroom.update_column(:trading_disabled_at, stale)
    # rubocop:enable Rails/SkipsModelValidations
    student.dismiss!(Dismissal::TRADING_OFF)

    classroom.reload.update!(trading_enabled: false)

    assert_operator classroom.reload.trading_disabled_at, :>, stale,
                    "a real switch-off must stamp its own date over a stale one"
    assert student.portfolio.reload.trading_off_notice?,
           "a dismissal made before this switch-off must not suppress it"
  end

  test "the onset is stamped once and not dragged forward by a resave" do
    classroom = create(:classroom, trading_enabled: false)
    stamped = classroom.trading_disabled_at

    assert_not_nil stamped

    travel 1.minute do
      classroom.update!(name: "Renamed")

      assert_equal stamped, classroom.reload.trading_disabled_at
    end
  end
end
