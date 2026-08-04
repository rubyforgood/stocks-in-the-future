# frozen_string_literal: true

require "test_helper"

# The ghost's contract, asserted here rather than in a system test because Tailwind v4 emits
# hover: utilities inside @media (hover:hover) and the headless Chromium the system tests drive
# reports (hover: none) - so the rose hover is real in a browser and invisible to Capybara.
class ButtonHelperTest < ActionView::TestCase
  include ButtonHelper

  test "both variants are slate at rest" do
    assert_includes ghost_class, "text-slate-600"
    assert_includes ghost_class(:danger), "text-slate-600"
  end

  test "no variant is red or rose at rest" do
    [ghost_class, ghost_class(:danger)].each do |classes|
      at_rest = classes.split.reject { |c| c.start_with?("hover:", "focus-visible:") }

      assert_empty at_rest.grep(/(rose|red)-/),
                   "a destructive action reveals danger on hover, not at rest: #{at_rest.join(' ')}"
    end
  end

  test "the danger variant hovers rose and the neutral one does not" do
    assert_includes ghost_class(:danger), "hover:text-rose-700"
    assert_includes ghost_class(:danger), "hover:bg-rose-50"
    assert_not_includes ghost_class, "rose"
  end

  test "an unknown variant falls back to neutral rather than raising" do
    assert_equal ghost_class(:neutral), ghost_class(:something_else)
  end

  test "the focus outline names its colour" do
    # Tailwind v4 resolves an unset ring/outline colour to currentColor, which is how a focus
    # indicator ends up invisible.
    assert_match(/focus-visible:outline-\S+/, ghost_class)
    assert_match(/focus-visible:outline-\S+/, ghost_class(:danger))
  end

  test "the ghost is 44px on touch and shorter on a desktop" do
    assert_includes ghost_class, "min-h-11"
    assert_includes ghost_class, "lg:min-h-8"
  end
end
