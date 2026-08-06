# frozen_string_literal: true

require "test_helper"

# The concern every dismissible banner now goes through. `since:` is the argument that makes a
# dismissal cover one instance of a condition rather than all of them, and it is the easiest thing
# here to get wrong by leaving out, so most of these are about it.
class DismissibleTest < ActiveSupport::TestCase
  setup { @user = create(:student) }

  test "nothing is dismissed to begin with" do
    assert_not @user.dismissed?(Dismissal::TRADING_OFF)
  end

  test "dismissing records it" do
    @user.dismiss!(Dismissal::TRADING_OFF)

    assert @user.dismissed?(Dismissal::TRADING_OFF)
  end

  test "keys do not leak into each other" do
    @user.dismiss!(Dismissal::TRADING_OFF)

    assert_not @user.dismissed?(Dismissal::FIRST_SHARE)
  end

  test "one row per user and key, however many times it is dismissed" do
    @user.dismiss!(Dismissal::TRADING_OFF)

    assert_difference -> { Dismissal.count }, 0 do
      @user.dismiss!(Dismissal::TRADING_OFF)
    end
  end

  test "dismissing again moves the date forward" do
    @user.dismiss!(Dismissal::TRADING_OFF)
    first = @user.dismissals.sole.dismissed_at

    travel 1.minute do
      @user.dismiss!(Dismissal::TRADING_OFF)

      assert_operator @user.dismissals.sole.reload.dismissed_at, :>, first
    end
  end

  # A dismissal made *after* the condition began covers it.
  test "a dismissal newer than the onset counts" do
    onset = 1.hour.ago
    @user.dismiss!(Dismissal::TRADING_OFF)

    assert @user.dismissed?(Dismissal::TRADING_OFF, since: onset)
  end

  # And one made *before* it does not - this is the whole reason the column is a timestamp.
  test "a dismissal older than the onset does not count" do
    @user.dismiss!(Dismissal::TRADING_OFF)

    travel 1.minute do
      assert_not @user.dismissed?(Dismissal::TRADING_OFF, since: Time.current)
    end
  end

  # nil covers both "cannot recur" and "onset unknown because the column was not backfilled".
  test "a nil onset honours the dismissal" do
    @user.dismiss!(Dismissal::TRADING_OFF)

    assert @user.dismissed?(Dismissal::TRADING_OFF, since: nil)
  end

  test "an unknown key is rejected rather than stored" do
    assert_raises(ActiveRecord::RecordInvalid) { @user.dismiss!("not_a_real_banner") }
  end

  test "dismissals go when the user goes" do
    @user.dismiss!(Dismissal::TRADING_OFF)

    assert_difference -> { Dismissal.count }, -1 do
      @user.really_destroy!
    end
  end
end
