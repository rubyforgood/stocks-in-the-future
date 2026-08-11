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

  # This is the assertion the section above was missing, and a preview found what it let through: the
  # app layout hardcoded `lg:top-16` on its sidebar while admin read `drawer_top_class`, so with the
  # ribbon on, admin's nav moved to 96 and the student's stayed at 64 - a third of it behind the
  # header. Asserting `main`'s top could not see it, because `main` was correct.
  test "the student sidebar drops with the header, exactly as admin's does" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    sign_in student

    in_staging do
      visit root_path

      tops = page.evaluate_script(<<~JS)
        (function () {
          const header = document.querySelector("header.fixed").getBoundingClientRect();
          const nav = document.querySelector("#main-navigation").getBoundingClientRect();
          return { headerTop: Math.round(header.top), headerBottom: Math.round(header.bottom),
                   navTop: Math.round(nav.top) };
        })()
      JS

      assert_equal 32, tops["headerTop"], "the header should sit under the ribbon"
      assert_equal 96, tops["navTop"], "the sidebar should start below the header, not behind it"
      assert_operator tops["navTop"], :>=, tops["headerBottom"], "the sidebar overlaps the header"
    end
  end

  # The mobile drawer is a full-height `top-0` overlay on the app side, so the ribbon has to outrank
  # it. It does at `z-60`, and - measured by reverting the class - it also did at `z-50`, purely
  # because it sits later in the layout. This test pins the outcome rather than the mechanism, which
  # is the point: the explicit rank is what stops a reorder from silently hiding the one thing on
  # screen saying this is not the real site. design.md asks for `elementFromPoint`, not the eye.
  test "an open mobile drawer does not cover the ribbon" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    sign_in student

    in_staging do
      in_phone_viewport do
        visit root_path
        find("[data-testid='open-navigation']").click

        # The rank has to be real, not just written. `z-60` is a Tailwind v4 utility rather than an
        # arbitrary value, and this asserts the compiled result - a class the build drops would leave
        # the tie in place while the markup read as fixed.
        assert_equal "60", page.evaluate_script(
          "getComputedStyle(document.querySelector(\"[data-testid='environment-ribbon']\")).zIndex"
        )

        assert_equal true, page.evaluate_script(<<~JS), "the drawer paints over the ribbon"
          (function () {
            const ribbon = document.querySelector("[data-testid='environment-ribbon']");
            const hit = document.elementFromPoint(180, 16);
            return ribbon.contains(hit) || hit === ribbon;
          })()
        JS
      end
    end
  end
end
