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

  # This replaces a test asserting the ribbon had **no** dismiss, and the reversal is deliberate: a 32px
  # band on every page of every visit was reported as "very distracting, and it pushes everything down".
  # What makes it safe is that it is not permanent - see the next test - and that a badge takes its
  # place, so the question "which deployment is this" is still answered.
  test "the ribbon can be put away, and the space is genuinely reclaimed" do
    sign_in create(:admin)

    in_staging do
      visit admin_root_path

      # Admin's main clears the chrome with padding rather than margin, so its own box starts at 0 and
      # the figure that matters is where its content begins.
      content_top = "Math.round(document.querySelector('main').firstElementChild.getBoundingClientRect().top)"
      assert_equal 96, page.evaluate_script(content_top),
                   "the band should be pushing content down to start with"

      click_on "Hide until next login"

      assert_no_selector "[data-testid='environment-ribbon']"
      assert_selector "[data-testid='environment-badge']", text: "Staging"

      assert_equal 64, page.evaluate_script(content_top), "the 32px should be back, not merely hidden"

      # The variable is what reclaims it, and it has to fall back rather than keep a stale value.
      assert_equal "0px", page.evaluate_script(
        "getComputedStyle(document.documentElement).getPropertyValue('--sitf-ribbon-h').trim()"
      )
    end
  end

  # The whole safety of making it dismissible rests on this. A permanent dismissal is the mute button
  # this codebase warns about, and its failure mode is somebody acting on staging months later believing
  # it is real.
  test "it comes back on the next login" do
    admin = create(:admin)
    sign_in admin

    in_staging do
      visit admin_root_path
      click_on "Hide until next login"
      assert_no_selector "[data-testid='environment-ribbon']"

      sign_out_through_the_ui
      fill_in "Username", with: admin.username
      fill_in "Password", with: "password"
      click_button "Sign in"

      assert_selector "[data-testid='environment-ribbon']", text: "Staging"
      assert_no_selector "[data-testid='environment-badge']"
    end
  end

  # Exactly one of the two, never both and never neither: two amber markers saying the same thing is the
  # third-copy-of-one-fact problem, and none at all is what the reversal had to avoid.
  test "the band and the badge are alternatives" do
    sign_in create(:admin)

    in_staging do
      visit admin_root_path
      assert_selector "[data-testid='environment-ribbon']"
      assert_no_selector "[data-testid='environment-badge']"

      click_on "Hide until next login"
      assert_no_selector "[data-testid='environment-ribbon']"
      assert_selector "[data-testid='environment-badge']"
    end
  end

  # Neither appears anywhere else, which is the point of the whole feature.
  test "no badge outside staging either" do
    sign_in create(:admin)
    visit admin_root_path

    assert_no_selector "[data-testid='environment-ribbon']"
    assert_no_selector "[data-testid='environment-badge']"
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

  # The sign-in page had no ribbon at all, which is the half of staging a person sees *first*. Its
  # header is in normal flow rather than fixed, so the ribbon is static there - a fixed one would
  # cover the header, and a static one needs no offsets, which is why it also skips the controller.
  test "the signed-out page carries it too, in normal flow" do
    in_staging do
      visit new_user_session_path

      assert_selector "[data-testid='environment-ribbon']", text: "Staging"

      m = page.evaluate_script(<<~JS)
        (function () {
          const r = document.querySelector("[data-testid='environment-ribbon']");
          const header = document.querySelector("header");
          return {
            position: getComputedStyle(r).position,
            controller: r.dataset.controller || null,
            ribbonBottom: Math.round(r.getBoundingClientRect().bottom),
            headerTop: Math.round(header.getBoundingClientRect().top)
          };
        })()
      JS

      # In flow, whatever the exact keyword: `relative` still occupies space, `fixed` and `absolute`
      # do not, and taking space is the whole difference here.
      assert_not_includes %w[fixed absolute], m["position"],
                          "a ribbon taken out of flow would cover the in-flow header"
      assert_nil m["controller"], "nothing is offset against it, so it should not publish a height"
      assert_operator m["headerTop"], :>=, m["ribbonBottom"], "the ribbon overlaps the header"
    end
  end

  # WCAG 1.4.4 (AA): at 200% text nothing may be lost. The ribbon's sentence wraps to four lines on a
  # phone at that size, and in the rigid `h-8` box it used to have, the overflow went **both** ways -
  # measured at 320px the text began at y=-48, above the top of the viewport, where a fixed element
  # cannot be scrolled to, and the rest of it covered the header.
  #
  # Doubling the ribbon's own font-size is the honest proxy here: the failure is the box, not the
  # zoom mechanism, and Selenium cannot drive browser zoom.
  test "at 200% text the ribbon grows instead of spilling out of a fixed box" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    sign_in student

    in_staging do
      in_phone_viewport do
        visit root_path
        page.execute_script(<<~JS)
          document.querySelector("[data-testid='environment-ribbon']").style.fontSize = "24px"
        JS
        # The ResizeObserver publishes on the next frame; there is no state to wait on but the number.
        sleep 0.3

        m = page.evaluate_script(<<~JS)
          (function () {
            const r = document.querySelector("[data-testid='environment-ribbon']");
            const box = r.getBoundingClientRect();
            const span = r.querySelector("span").getBoundingClientRect();
            const header = document.querySelector(".chrome-header").getBoundingClientRect();
            return {
              ribbon: Math.round(box.height),
              textTop: Math.round(span.top),
              textBottom: Math.round(span.bottom),
              headerTop: Math.round(header.top),
              mainTop: Math.round(document.querySelector("main").getBoundingClientRect().top)
            };
          })()
        JS

        assert_operator m["ribbon"], :>, 32, "the ribbon did not grow with its text"
        assert_operator m["textTop"], :>=, 0, "text is above the top of the viewport, unreachable"
        assert_operator m["textBottom"], :<=, m["ribbon"], "text spills out of the ribbon"
        assert_equal m["ribbon"], m["headerTop"], "the header does not follow the ribbon's height"
        assert_equal m["ribbon"] + 64, m["mainTop"], "content does not clear the grown chrome"
      end
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
