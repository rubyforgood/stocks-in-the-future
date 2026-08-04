# frozen_string_literal: true

require "application_system_test_case"

# The rendered button variants against design.md's Buttons section.
#
# Every variant shares a base of `inline-flex h-10 items-center justify-center gap-2 rounded-lg
# px-4 text-sm shadow-sm`; filled variants are font-semibold and outlined ones font-medium; the
# outline is `border border-slate-200`.
#
# They had drifted, in five separate ways, because the same base was written twice - once in
# buttons.css and once as ADMIN_BUTTON_BASE in Ruby - and pasted per variant inside each:
# `ring-1 ring-slate-300` instead of the border, `border-slate-300` instead of slate-200,
# `font-medium` on the filled variants, a `border border-transparent` design.md rules out by name,
# and a missing `justify-center` on the admin base. None of it is visible in a class list, and
# "it uses the named secondary class" is not the same as "it matches the spec".
class ButtonVariantsTest < ApplicationSystemTestCase
  FILLED = %w[tw-btn-primary tw-btn-primary-disabled].freeze
  OUTLINED = %w[tw-btn-secondary tw-btn-danger-outline].freeze
  ALL = (FILLED + OUTLINED).freeze

  SLATE_200 = "oklch(0.929 0.013 255.508)"

  def computed(css_class)
    page.evaluate_script(<<~JS)
      (function () {
        const el = document.createElement("button");
        el.className = #{css_class.to_json};
        el.textContent = "Sample";
        document.body.appendChild(el);
        const s = getComputedStyle(el);
        const out = {
          height: s.height,
          radius: s.borderTopLeftRadius,
          fontSize: s.fontSize,
          weight: s.fontWeight,
          justify: s.justifyContent,
          align: s.alignItems,
          display: s.display,
          gap: s.columnGap,
          padding: s.paddingLeft,
          borderWidth: s.borderTopWidth,
          borderColour: s.borderTopColor,
          shadow: s.boxShadow
        };
        el.remove();
        return out;
      })()
    JS
  end

  def setup_page
    sign_in(create(:admin))
    visit admin_users_path
  end

  test "every variant shares design.md's base" do
    setup_page

    ALL.each do |variant|
      c = computed(variant)

      assert_equal "40px", c["height"], "#{variant} is not on the h-10 height token"
      assert_equal "8px", c["radius"], "#{variant} is not rounded-lg"
      assert_equal "14px", c["fontSize"], "#{variant} is not text-sm"
      assert_equal "inline-flex", c["display"], "#{variant} is not inline-flex"
      assert_equal "center", c["justify"], "#{variant} is missing justify-center"
      assert_equal "center", c["align"], "#{variant} is missing items-center"
      assert_equal "8px", c["gap"], "#{variant} is not gap-2"
      assert_equal "16px", c["padding"], "#{variant} is not px-4"
      assert_not_equal "none", c["shadow"], "#{variant} is missing shadow-sm"
    end
  end

  test "filled variants are semibold and carry no border" do
    setup_page

    FILLED.each do |variant|
      c = computed(variant)

      assert_equal "600", c["weight"], "#{variant} should be font-semibold"
      # design.md: do not re-equalise heights with `border border-transparent` on a filled
      # variant - the h-10 token already absorbs the outlined variant's border.
      assert_equal "0px", c["borderWidth"],
                   "#{variant} carries a border; the height token equalises the variants instead"
    end
  end

  test "outlined variants are medium weight on a 1px slate-200 border" do
    setup_page

    OUTLINED.each do |variant|
      c = computed(variant)

      assert_equal "500", c["weight"], "#{variant} should be font-medium"
      assert_equal "1px", c["borderWidth"], "#{variant} should have a 1px border"
      assert_equal SLATE_200, c["borderColour"],
                   "#{variant} should be border-slate-200. slate-300 measured darker and read as " \
                   "too heavy; a ring is not a border"
    end
  end

  test "the danger outline is indistinguishable from secondary at rest" do
    setup_page

    secondary = computed("tw-btn-secondary")
    danger = computed("tw-btn-danger-outline")

    %w[height radius fontSize weight borderWidth borderColour].each do |property|
      assert_equal secondary[property], danger[property],
                   "danger-outline differs from secondary at rest on #{property}; there is no " \
                   "red at rest, and it has to match the bordered buttons beside it"
    end
  end

  # The admin helpers are aliases now rather than a second set of strings. If someone reintroduces
  # a separate admin base, these stop matching.
  test "admin and app buttons are the same classes" do
    assert_equal "tw-btn-primary", ApplicationController.helpers.admin_primary_button_class
    assert_equal "tw-btn-secondary", ApplicationController.helpers.admin_secondary_button_class
    assert_equal "tw-btn-danger-outline", ApplicationController.helpers.admin_danger_button_class
  end
end
