# frozen_string_literal: true

require "application_system_test_case"

# Measured spacing, not class names.
#
# The gap under a header was reported wrong three times on this branch, and each time reading
# the classes said it was correct. It was not: pb-5 stacked on mb-6 under the page title; py-4
# stacked on p-5 inside the card; and a 40px CTA in an items-start row left 8px of dead space
# below a 32px h1, so a header that read as mb-6 rendered a 32px gap. Only the rendered geometry
# shows any of that, so these assert pixels.
class SpacingTest < ApplicationSystemTestCase
  TOLERANCE = 2

  # design.md: the header block is mb-6 (24px), and nothing else.
  HEADER_GAP = 24

  # A card's header rule gets equal padding either side - 16px, as Stripe's Box and Primer's
  # Box.Header use - rather than the header's py-4 stacking on a full p-5 body.
  CARD_SEAM = 32

  def distance(from_selector, to_selector)
    page.evaluate_script(<<~JS)
      (function () {
        const a = document.querySelector(#{from_selector.to_json});
        const b = document.querySelector(#{to_selector.to_json});
        if (!a || !b) return null;
        return Math.round(b.getBoundingClientRect().top - a.getBoundingClientRect().bottom);
      })()
    JS
  end

  # admin/schools, not admin/users: the users list gained the discard filter tabs when `restore` was
  # added, and design.md is explicit that filters sit *between* the header and the card. So the h1-to-card
  # distance there is the header gap plus the tabs, and measuring it would be measuring the wrong thing.
  # `page_rhythm_test` asserts the header block's own 24px on every page including that one; this checks
  # the case where the card is genuinely the next thing.
  test "a title-only page header leaves 24px above the content" do
    sign_in(create(:admin))
    create(:school)
    visit admin_schools_path

    gap = distance("main h1", ".tw-card")

    assert_not_nil gap, "expected an h1 and a card on the admin schools index"
    assert_in_delta HEADER_GAP, gap, TOLERANCE,
                    "title to card measured #{gap}px; a 40px action beside a 32px h1 in an " \
                    "items-start row is the usual cause"
  end

  # **The gallery, not a record page.** This used `admin/stocks#show`, which had a titled "Price information"
  # card until the record page absorbed it - the form edits both prices, so a read-only card of them was the
  # same numbers twice. A titled card is rarer now that a section's heading carries the title, and the gallery
  # is the one page guaranteed to render every component, which `component_gallery_test` enforces.
  test "a card header leaves 32px between its title and the content" do
    sign_in(create(:admin))
    visit admin_component_demo_index_path

    gap = page.evaluate_script(<<~JS)
      (function () {
        const head = document.querySelector("section.tw-card > header");
        if (!head) return null;
        const body = head.nextElementSibling;
        const title = head.querySelector("h2");
        const first = body.firstElementChild || body;
        return Math.round(first.getBoundingClientRect().top - title.getBoundingClientRect().bottom);
      })()
    JS

    assert_not_nil gap, "expected a titled card in the component gallery"
    assert_in_delta CARD_SEAM, gap, TOLERANCE,
                    "card header to content measured #{gap}px; the header's padding stacking " \
                    "on a full p-5 body is the usual cause"
  end
  # The nav is the thing most likely to grow past a short viewport: someone adds a section and
  # nobody notices, because the default test window is 1400px tall and no real screen is. Ten
  # admin links at 44px with 24px section gaps measured 636px against 561px of available height
  # and scrolled; at 36px they measure 561px and do not.
  test "the admin sidebar fits a Chromebook without scrolling" do
    sign_in(create(:admin))

    in_chromebook_viewport do
      visit admin_root_path

      overflow = page.evaluate_script(<<~JS)
        (function () {
          const nav = document.querySelector("#admin-navigation");
          if (!nav) return null;
          return nav.scrollHeight - nav.clientHeight;
        })()
      JS

      assert_not_nil overflow, "expected the admin sidebar to be present"
      assert overflow <= 0,
             "the admin sidebar overflows a 1366x768 Chromebook by #{overflow}px; a nav row is " \
             "36px at lg, so this usually means rows or sections were added or loosened"
    end
  end
  # Every row the same height, which is what "one row treatment" has to mean in pixels.
  #
  # The component demo row was hand-rolled rather than built from NavHelper, so it kept `min-h-11 py-2` with
  # no `lg:` step and rendered 44px against every neighbour's 36px at 1366px. It was invisible to this file
  # until its guard moved from `Rails.env.development?` to `local?`, at which point the test above - the
  # sidebar fits a Chromebook - failed by 67px, because ten rows are 561px in 561px and there is no room for
  # an eleventh. The row is a top-bar link now; this asserts the ten that remain agree with each other.
  test "every admin nav row is the same height, at both widths" do
    sign_in(create(:admin))

    heights = <<~JS
      (function () {
        const rows = [...document.querySelectorAll("#admin-navigation a")];
        return rows.map(function (a) {
          return { label: a.textContent.trim(), h: Math.round(a.getBoundingClientRect().height) };
        });
      })()
    JS

    { chromebook: 36, phone: 44 }.each do |viewport, expected|
      method(:"in_#{viewport == :chromebook ? 'chromebook' : 'phone'}_viewport").call do
        visit admin_root_path
        rows = page.evaluate_script(heights)

        assert_operator rows.size, :>=, 10, "expected the ten product section rows"
        rows.each do |row|
          assert_equal expected, row["h"],
                       "the #{row['label']} nav row is #{row['h']}px on a #{viewport}, not #{expected}px - " \
                       "a row built by hand instead of from NavHelper is the usual cause"
        end
      end
    end
  end

  # Admin tables hand-wrote their cell padding as px-3 py-4 while their headers used the shared
  # table-header-cell at px-4 py-3, so every column's header text sat 4px off its own data. Both
  # sides use the shared classes now; this asserts a column actually lines up.
  test "a table header lines up with its column" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.portfolio.portfolio_transactions.create!(
      amount_cents: 500, transaction_type: :deposit,
      reason: :math_earnings
    )
    sign_in(create(:admin))
    visit admin_portfolio_transactions_path

    offset = page.evaluate_script(<<~JS)
      (function () {
        const th = document.querySelector("thead th");
        const td = document.querySelector("tbody td");
        if (!th || !td) return null;
        return Math.round(th.getBoundingClientRect().left - td.getBoundingClientRect().left);
      })()
    JS

    assert_not_nil offset, "expected a table with a header and a body row"
    assert_in_delta 0, offset, 1,
                    "the header is #{offset}px off its column; admin tables writing their own " \
                    "cell padding instead of the shared table-* classes is the usual cause"
  end
  # The layout owns the gutter between the sidebar and the content. When a page added its own
  # horizontal padding on top of main's, the app rendered 48px against admin's 24px - and 53px on
  # home, where a narrower max-width let mx-auto centre the column and widen it further.
  GUTTER = 24

  test "the gutter between sidebar and content is the same on both sides" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))

    sign_in(create(:admin))
    visit admin_users_path

    assert_in_delta GUTTER, sidebar_to_content_gutter(".tw-card"), 2,
                    "admin content gutter is off"

    sign_out(:user)
    sign_in(student)
    visit root_path

    assert_in_delta GUTTER, sidebar_to_content_gutter("section.tw-card"), 2,
                    "app content gutter is off; a page adding its own px on top of main's, or a " \
                    "max-width narrow enough for mx-auto to centre it, are the usual causes"
  end

  # The section rhythm. Nine places used 32px or 64px instead - gap-8 between panes, space-y-8
  # between sections, mt-8 on children that a flex row already spaced, and pb-16 or px-6 lg:px-8
  # on top of the padding main already provides. Asserting the gap between top-level sections
  # catches a page reintroducing its own.
  RHYTHM = 24

  test "sections on a page are 24px apart" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 100_000)

    sign_in(student)

    [root_path, stocks_path].each do |path|
      visit path

      section_gaps.each do |gap|
        assert_in_delta RHYTHM, gap, TOLERANCE,
                        "#{path} has a #{gap}px gap between sections; the rhythm is #{RHYTHM}px"
      end
    end
  end

  # An auth page is not inside the sidebar layout, so its own padding is the only gutter there
  # is - and both of them set px-6 lg:px-8 on top of main's p-4 lg:p-6, which put the sign-in
  # card 40px from the edge of a 375px phone while every other page sat at 16px.
  test "the sign-in card sits on the same edge as every other page" do
    # in_phone_viewport, not a bare resize_to: Capybara reuses one browser for the suite, so a
    # test that resizes and does not restore hands a 375px window to whatever runs next. This
    # test did exactly that for one commit, and the page-header test above it failed about one
    # run in three - at 375px the header stacks, so its 40px action sits below the h1 and the
    # gap to the card measures 76px instead of 24px. It looked like a spacing regression.
    in_phone_viewport do
      visit new_user_session_path

      left, right = page.evaluate_script(<<~JS)
        (function () {
          const b = document.querySelector("main form, main > div > div").getBoundingClientRect();
          return [Math.round(b.left), Math.round(document.documentElement.clientWidth - b.right)];
        })()
      JS

      assert_in_delta 16, left, TOLERANCE, "sign-in is not on the standard 16px edge"
      assert_in_delta 16, right, TOLERANCE, "sign-in is not on the standard 16px edge"
    end
  end

  # The gutter above the page title, which was **zero** on every signed-in page. <main> there was
  # `px-4 lg:px-6 ... mt-16 pb-6`: sides and bottom, and no padding-top. mt-16 clears the fixed 64px
  # nav and is not padding, which is what made it easy to miss - and an earlier sweep removed the
  # per-page `py-6` / `pt-4` that had been supplying the gap, citing "main's p-4 lg:p-6", which was
  # only ever the *signed-out* branch's class. Measured before: home 0px, portfolio 0px, trading
  # floor 8px (its own header's items-end), orders 24px (it still had pt-6).
  test "every page leaves the same gutter above its title" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    admin = create(:admin)

    sign_in student
    [root_path, stocks_path, orders_path].each do |path|
      assert_title_gutter(path, 24)
    end

    sign_out(:user)
    sign_in admin

    # Admin *record* pages put a breadcrumb trail above the header, so their title sits lower - an index has
    # no trail, because a one-level one names the page its h1 has just named. The gutter measured here is the
    # one above the whole content block either way.
    assert_title_gutter(admin_root_path, 24)
  end

  test "the title gutter is 16px on a phone" do
    student = create(:student, :with_portfolio, classroom: create(:classroom, :with_trading))
    student.reload
    sign_in student

    in_phone_viewport do
      assert_title_gutter(root_path, 16)
    end
  end

  # A section heading, the line explaining it, and the thing it labels. _stocks_table emitted these
  # as three top-level elements into a `space-y-6` container, and
  # `space-y-6 > :not([hidden]) ~ :not([hidden])` outspecifies a plain mt-1 or mt-3 - so all three
  # sat 24px apart while the markup said 4px and 12px. A partial rendered into a space-y-* container
  # needs a single root element.
  test "a section heading sits 4px above its helper line and 12px above its table" do
    classroom = create(:classroom, :with_trading)
    student = create(:student, :with_portfolio, classroom:)
    student.reload
    create(:stock, ticker: "AAA", company_name: "Alpha", price_cents: 1000)
    sign_in student

    visit stocks_path

    gaps = page.evaluate_script(<<~JS)
      (function () {
        const h2 = document.querySelector("main h2");
        const helper = h2.nextElementSibling;
        const table = helper.nextElementSibling;
        return [Math.round(helper.getBoundingClientRect().top - h2.getBoundingClientRect().bottom),
                Math.round(table.getBoundingClientRect().top - helper.getBoundingClientRect().bottom)];
      })()
    JS

    assert_in_delta 4, gaps[0], TOLERANCE, "heading to helper line"
    assert_in_delta 12, gaps[1], TOLERANCE, "helper line to table"
  end

  def assert_title_gutter(path, expected)
    visit path

    gutter = page.evaluate_script(<<~JS)
      (function () {
        const main = document.querySelector("main");
        const inner = main.querySelector(":scope > div[class*='p-4'], :scope > div[class*='p-6']") || main;
        const first = inner.firstElementChild;
        return Math.round(first.getBoundingClientRect().top - inner.getBoundingClientRect().top);
      })()
    JS

    assert_in_delta expected, gutter, TOLERANCE,
                    "#{path} leaves #{gutter}px above its content, not #{expected}px; <main> has " \
                    "no padding-top of its own on the signed-in side"
  end

  # Reported as too much padding between the checkboxes, and it was three spacings doing one job: `py-2` on
  # each row, `space-y-2` between them, so 24px of air between one option's text and the next.
  #
  # The row carries a `hover:bg-slate-50` fill, which puts it in Primer's ActionList and Material's list
  # family - both run their rows edge to edge, because a gap between two fills reads as a hole. So the
  # padding is the whole of the separation and the gap is zero. Polaris's bare ChoiceList is the other
  # consistent answer (a gap, no padding) and not this component.
  test "a checkbox group's rows are contiguous, so the row padding is the only gap" do
    sign_in(create(:admin))
    school = create(:school)
    year = Year.current_school_year.first_or_create!(name: Year.current_school_year_name)
    school_year = create(:school_year, school:, year:)
    2.times { |i| create(:classroom, name: "Grade #{i + 5}", school_year:) }

    visit new_admin_teacher_path

    rows = page.evaluate_script(<<~JS)
      (function () {
        const labels = Array.from(document.querySelectorAll("fieldset label")).filter(function (l) {
          return l.querySelector("input[type=checkbox]") && l.getClientRects().length > 0;
        });
        if (labels.length < 2) return null;
        const a = labels[0].getBoundingClientRect(), b = labels[1].getBoundingClientRect();
        return { gap: Math.round(b.top - a.bottom), pitch: Math.round(b.top - a.top),
                 height: Math.round(a.height) };
      })()
    JS

    assert rows, "expected at least two classroom checkboxes to measure"
    assert_equal 0, rows["gap"],
                 "#{rows['gap']}px between two checkbox rows. The row's own py-2 is the separation; a " \
                 "gap on top of it is the same space declared twice"
    assert_equal rows["height"], rows["pitch"],
                 "the pitch should be the row's own height once the rows are contiguous"
  end

  # The page's own top-level children, which are one level deeper than they look. `main > div` is the
  # layout's content column - it wraps the flash and the yield together so a banner cannot be a
  # different width from the page under it - so the page's root is the column's *last* child, and its
  # children are the sections. This read `main > div > *`, which was the page's sections back when the
  # page's own wrapper was main's only child; after the column arrived it returned one element, the
  # loop below never ran, and the test passed while asserting nothing. Minitest's "missing assertions"
  # warning was the only sign.
  def section_gaps
    page.evaluate_script(<<~JS)
      (function () {
        const column = document.querySelector("main > div.max-w-7xl") || document.querySelector("main > div");
        const root = column && column.lastElementChild ? column.lastElementChild : column;
        const kids = Array.from(root ? root.children : []);
        const out = [];
        for (let i = 0; i < kids.length - 1; i++) {
          const a = kids[i].getBoundingClientRect(), b = kids[i + 1].getBoundingClientRect();
          if (a.height > 0 && b.height > 0) out.push(Math.round(b.top - a.bottom));
        }
        return out;
      })()
    JS
  end

  def sidebar_to_content_gutter(card_selector)
    page.evaluate_script(<<~JS)
      (function () {
        const nav = document.querySelector("nav[aria-label='Main'], #admin-navigation");
        const card = document.querySelector(#{card_selector.to_json});
        if (!nav || !card) return null;
        return Math.round(card.getBoundingClientRect().left - nav.getBoundingClientRect().right);
      })()
    JS
  end
end
