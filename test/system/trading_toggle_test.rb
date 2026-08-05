# frozen_string_literal: true

require "application_system_test_case"

# The trading switch on classrooms#show submitted its form from an inline
# `onchange="this.form.requestSubmit()"`, the last inline handler in the app. It is a Stimulus
# action now, and nothing covered it - so a mechanism change to a teacher-facing control that gates
# whether a whole classroom can trade would have been silent.
class TradingToggleTest < ApplicationSystemTestCase
  setup do
    @classroom = create(:classroom)
    @teacher = create(:teacher)
    @teacher.classrooms << @classroom
  end

  test "a teacher turns trading on and off for their own classroom" do
    assert_not @classroom.trading_enabled?, "expected the factory classroom to start with trading off"

    sign_in @teacher
    visit classroom_path(@classroom)

    check "trading", allow_label_click: true

    assert_selector "input#trading[checked]", wait: 5
    assert @classroom.reload.trading_enabled?, "the switch did not turn trading on"

    uncheck "trading", allow_label_click: true

    assert_no_selector "input#trading[checked]", wait: 5
    assert_not @classroom.reload.trading_enabled?, "the switch did not turn trading off"
  end

  test "an admin turns trading on for any classroom" do
    sign_in create(:admin)
    visit classroom_path(@classroom)

    check "trading", allow_label_click: true

    assert_selector "input#trading[checked]", wait: 5
    assert @classroom.reload.trading_enabled?
  end

  # The switch renders `disabled` unless the viewer may toggle, and that branch turns out to be
  # unreachable: classrooms_controller#check_classroom_eligibility admits only admins and the
  # classroom's own teachers, and both may toggle. It stays as an authorization guard - the
  # eligibility rule is the kind of thing that loosens - but the enforcement that actually holds is
  # the redirect, so that is what is asserted.
  test "a teacher cannot reach a classroom that is not theirs" do
    other = create(:classroom)

    sign_in @teacher
    visit classroom_path(other)

    assert_current_path root_path
    assert_no_selector "input#trading"
  end
end
