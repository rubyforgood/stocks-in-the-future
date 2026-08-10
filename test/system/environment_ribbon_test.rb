# frozen_string_literal: true

require "application_system_test_case"

# The staging ribbon: which deployment am I looking at.
#
# An admin on staging had nothing on screen telling them the data was not real. It is deliberately not
# shown in development - the URL says localhost there, and a permanent stripe on every page of every
# working day is noise that teaches you to stop seeing it, which is exactly what would make it useless on
# staging.
#
# The suite runs in the test environment, so these stub `Rails.env` rather than assert the default. That
# is the only honest way to cover an environment the tests are not running in - and the alternative,
# leaving it uncovered, is how the component demo's nav row kept a 44px height for months.
class EnvironmentRibbonTest < ApplicationSystemTestCase
  def in_staging
    Rails.env = "staging"
    yield
  ensure
    Rails.env = "test"
  end

  test "no ribbon outside staging, and the header sits at the top" do
    sign_in create(:admin)
    visit admin_root_path

    assert_no_selector "[data-testid='environment-ribbon']"
    assert_equal 0, page.evaluate_script(
      "Math.round(document.querySelector('body > div.fixed').getBoundingClientRect().top)"
    )
  end

  test "on staging the ribbon shows and everything fixed below it moves down" do
    sign_in create(:admin)

    in_staging do
      visit admin_root_path

      assert_selector "[data-testid='environment-ribbon']", text: "Staging"

      geometry = page.evaluate_script(<<~JS)
        (function () {
          const ribbon = document.querySelector("[data-testid='environment-ribbon']");
          const header = [...document.querySelectorAll("body > div.fixed")]
            .find(el => el !== ribbon);
          const nav = document.querySelector("#admin-navigation");
          const main = document.querySelector("main");
          return {
            ribbon: Math.round(ribbon.getBoundingClientRect().height),
            headerTop: Math.round(header.getBoundingClientRect().top),
            navTop: Math.round(nav.getBoundingClientRect().top),
            mainTop: Math.round(main.querySelector("*").getBoundingClientRect().top)
          };
        })()
      JS

      # 32px of ribbon, then the 64px header, then everything else.
      assert_equal 32, geometry["ribbon"]
      assert_equal 32, geometry["headerTop"], "the header is still at the top, under the ribbon"
      assert_equal 96, geometry["navTop"], "the drawer did not move down with the header"
      assert_operator geometry["mainTop"], :>=, 96, "content is behind the header"
    end
  end

  test "the ribbon does not offer to be dismissed, because the environment is still true in a minute" do
    sign_in create(:admin)

    in_staging do
      visit admin_root_path

      within "[data-testid='environment-ribbon']" do
        assert_no_selector "button"
        assert_no_selector "a"
      end
    end
  end

  test "the student side gets it too, since one product means one chrome" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    sign_in student

    in_staging do
      visit root_path

      assert_selector "[data-testid='environment-ribbon']"
      assert_equal 96, page.evaluate_script(
        "Math.round(document.querySelector('main').getBoundingClientRect().top)"
      )
    end
  end
end
