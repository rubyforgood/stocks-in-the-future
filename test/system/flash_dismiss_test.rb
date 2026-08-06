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

  # The manual half of the model. Both flash banners can be closed - the notice sooner than its
  # timer, the alert at all - and closing is the *only* way the alert goes.
  test "the success notice can be closed before its timer" do
    student_who_can_sign_in("closer")
    sign_in_through_the_form("closer")

    assert_selector "#notice"
    within("#notice") { click_on "Dismiss" }

    assert_no_selector "#notice", wait: 2
  end

  test "the error alert can be closed, which is the only way it goes" do
    student_who_can_sign_in("errcloser")

    visit new_user_session_path
    fill_in "Username", with: "errcloser"
    fill_in "Password", with: "wrong-on-purpose"
    click_on "Sign in"

    assert_selector "#alert"
    within("#alert") { click_on "Dismiss" }

    assert_no_selector "#alert", wait: 2
  end

  # A bare icon control needs its own accessible name - lucide_icon renders aria-hidden - and it is
  # the one case where this app uses 44px rather than the 32px a labelled ghost button gets.
  test "each flash close control is named and 44px" do
    student_who_can_sign_in("a11ycheck")
    sign_in_through_the_form("a11ycheck")

    assert_selector "#notice button", text: "Dismiss"

    box = page.evaluate_script(<<~JS)
      (function () {
        const b = document.querySelector("#notice button").getBoundingClientRect();
        return [Math.round(b.width), Math.round(b.height)];
      })()
    JS

    assert_operator box[0], :>=, 44, "the close target is #{box[0]}px wide"
    assert_operator box[1], :>=, 44, "the close target is #{box[1]}px tall"
  end

  # Page state and error summaries stick *and* have no close control: a dismissal that is not
  # remembered comes back on the next page load, which reads as broken. Where a callout genuinely is
  # dismissible the dismissal is persisted - a button_to posting to `dismissals` - so asserting on the
  # `dismiss` controller rather than on the presence of a button is what distinguishes the two.
  test "a callout has no client-side close, and its persisted one is a real form" do
    classroom = create(:classroom, trading_enabled: false)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    sign_in student

    visit stocks_path
    assert_text "Trading is turned off"
    assert_no_selector "[data-controller~='dismiss']"
    assert_selector "form[action*='dismissals']"
  end

  # The whole point of persisting it: a reload is the test a client-side hide fails.
  test "dismissing the trading callout survives a reload, on both pages" do
    classroom = create(:classroom, trading_enabled: false)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    sign_in student

    visit stocks_path
    assert_text "Trading is turned off"
    click_on "Dismiss"

    assert_no_text "Trading is turned off"

    visit stocks_path
    assert_no_text "Trading is turned off"

    visit user_portfolio_path(student, student.portfolio)
    assert_no_text "Trading is turned off"
  end

  # The condition recurring is the case a client-side hide and a boolean column both get wrong.
  test "the trading callout returns after trading is switched off again" do
    classroom = create(:classroom, trading_enabled: false)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    sign_in student

    visit stocks_path
    click_on "Dismiss"
    assert_no_text "Trading is turned off"

    classroom.update!(trading_enabled: true)
    travel 1.minute do
      classroom.update!(trading_enabled: false)

      visit stocks_path

      assert has_text?("Trading is turned off"),
             "a dismissal must cover the switch-off it was made against, not every later one"
    end
  end

  # The callout inside admin/teachers/_form must never get one: button_to renders a <form>, the parser
  # drops a nested one, and the button would silently submit the teacher form instead.
  test "the callout inside a form has no dismiss button" do
    sign_in create(:admin)

    visit new_admin_teacher_path

    within("form") do
      assert_no_selector "form", text: "Dismiss"
    end
  end

  test "the first-share callout dismisses by posting, not by hiding" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    stock = create(:stock, ticker: "AAA", company_name: "Alpha", price_cents: 1000)
    # The factory, not a bare create!: the holdings table reads purchase_price to work out the
    # change, and a nil there is an ActionView error rather than a missing callout.
    create(:portfolio_stock, portfolio: student.portfolio, stock:, shares: 1)
    sign_in student

    visit user_portfolio_path(student, student.portfolio)

    if has_selector?("[data-testid='first-share']", wait: 2)
      within("[data-testid='first-share']") do
        assert_not has_selector?("[data-action~='dismiss#now']", wait: 0),
                   "the first-share dismiss must persist, not hide: a callout that vanishes " \
                   "without a round trip is back on the next page load"
        assert_selector "form"
      end
    else
      skip "first-share callout did not render for this fixture"
    end
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
