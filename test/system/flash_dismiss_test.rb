# frozen_string_literal: true

require "application_system_test_case"

# Success auto-hides, errors stay, and nothing else in the app dismisses itself.
#
# The delay is real time here rather than a shortened one, because the number is the decision: 6s,
# where the field runs 3-10s and clusters at 4-6. A test that shortened it would assert that a timer
# exists and say nothing about the value shipped.
class FlashDismissTest < ApplicationSystemTestCase
  # 6s plus the 300ms fade plus room for a slow CI box. The margin is deliberately generous: a
  # too-tight bound on a timer is the classic flaky test, and the assertion that matters is "it goes",
  # not "it goes within a millisecond of six seconds".
  GONE_WITHIN = 12

  # Comfortably inside the delay. If this fails the message is vanishing too early, which is the
  # failure a reader would actually complain about.
  STILL_THERE_AT = 3

  # Past the delay, so "still on screen" can only mean the timer never fired.
  PAST_THE_DELAY = 8

  def sign_in_through_the_form(username)
    visit new_user_session_path
    fill_in "Username", with: username
    fill_in "Password", with: "Passw0rd"
    click_on "Sign in"
  end

  def student_who_can_sign_in(username)
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:, username:)
    student.reload
    student
  end

  test "a success notice clears itself after six seconds" do
    student_who_can_sign_in("dismisser")
    sign_in_through_the_form("dismisser")

    assert_selector "#notice", text: "Signed in successfully"

    sleep STILL_THERE_AT
    assert_selector "#notice", text: "Signed in successfully", wait: 0

    assert_no_selector "#notice", wait: GONE_WITHIN
  end

  # The other half of the convention, and the reason the controller is on one branch of the partial
  # rather than on the partial: an error is often the only record of what went wrong.
  test "an error alert is never dismissed" do
    student_who_can_sign_in("staysput")

    visit new_user_session_path
    fill_in "Username", with: "staysput"
    fill_in "Password", with: "wrong-on-purpose"
    click_on "Sign in"

    assert_selector "#alert"

    sleep PAST_THE_DELAY
    assert_selector "#alert", wait: 0
  end

  # WCAG 2.2.1: it cannot vanish mid-read.
  test "hovering holds the notice, and leaving lets it go" do
    student_who_can_sign_in("hoverer")
    sign_in_through_the_form("hoverer")

    assert_selector "#notice"
    find("#notice").hover

    sleep PAST_THE_DELAY
    assert_selector "#notice", wait: 0

    # Anywhere that is not the notice, which fires mouseleave and restarts the delay.
    find("h1", match: :first).hover
    assert_no_selector "#notice", wait: GONE_WITHIN
  end

  # The sweep. A callout is page state - "trading is turned off" is true until a teacher changes it -
  # and a form error summary is the same shape as the alert. Neither may carry the controller, and the
  # assertion is written against the attribute rather than by waiting, so it names the cause.
  test "no callout and no error summary dismisses itself" do
    classroom = create(:classroom, trading_enabled: false)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    sign_in student

    visit stocks_path
    assert_text "Trading is turned off"
    assert_no_dismissers("the trading floor callout")

    visit user_portfolio_path(student, student.portfolio)
    assert_no_dismissers("the portfolio callout")
  end

  test "a form error summary does not dismiss itself" do
    classroom = create(:classroom, :with_trading)
    teacher = create(:teacher)
    create(:teacher_classroom, teacher:, classroom:)
    sign_in teacher

    # A duplicate username, not a blank one: the field is `required`, so a blank submit is stopped by
    # the browser and never reaches the validation that renders the summary.
    create(:student, classroom:, username: "taken")

    visit new_classroom_student_path(classroom)
    fill_in "Username", with: "taken"
    click_on "Create student"

    assert_selector "[role='alert']", text: "Error"
    assert_no_dismissers("the students#new error summary")
  end

  # Only the flash notice may carry it. Anything else with the controller is a banner that will
  # delete itself off a page that still means what it says.
  def assert_no_dismissers(label)
    stray = page.evaluate_script(<<~JS)
      (function () {
        const out = [];
        document.querySelectorAll("[data-controller~='auto-dismiss']").forEach(function (el) {
          if (el.id !== "notice") out.push(el.tagName.toLowerCase() + "#" + el.id + "." + String(el.className).slice(0, 40));
        });
        return out;
      })()
    JS

    assert_empty stray, "#{label} carries data-controller=\"auto-dismiss\". Only the flash notice " \
                        "may dismiss itself; page state and errors stay."
  end
end
