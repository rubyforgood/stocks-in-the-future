# frozen_string_literal: true

require "test_helper"

class AdminHelperTest < ActionView::TestCase
  test "format_attribute formats boolean true" do
    user = build(:admin)
    result = format_attribute(user, :admin)
    assert_match(/Yes/, result)
    assert_match(/rounded-full/, result)
  end

  test "format_attribute formats boolean false" do
    user = build(:student)
    result = format_attribute(user, :admin)
    assert_match(/No/, result)
    assert_match(/slate/, result)
  end

  test "format_attribute formats date" do
    date = Date.new(2025, 12, 22)
    user = build(:student, created_at: date)
    result = format_attribute(user, :created_at)
    assert_equal "December 22, 2025", result
  end

  test "format_attribute formats nil value" do
    user = build(:student, name: nil)
    result = format_attribute(user, :name)
    assert_match(/—/, result)
    # slate-600, raised from slate-500 for WCAG 1.4.6: an absent value is text, and 4.76:1 clears AA but
    # not the 7:1 the enhanced criterion asks for. slate-600 is 7.58:1. This dash has been measured twice
    # before - it shipped at 2.6:1 and failed AA outright.
    assert_match(/text-slate-600/, result)
  end

  test "format_attribute formats string" do
    user = build(:student, email: "test@example.com")
    result = format_attribute(user, :email)
    assert_equal "test@example.com", result
  end

  # Deliberately no hue in these. Pinning bg-green-100 once blocked the move onto the shared
  # component, and then pinning /green/ blocked the move onto design.md's emerald. What matters
  # is the label, the badge scale, and that true and false are visually distinct - assert that
  # rather than the palette of the day.
  test "boolean_badge renders yes and no through the shared component" do
    yes = boolean_badge(true)
    no = boolean_badge(false)

    assert_match(/Yes/, yes)
    assert_match(/No/, no)

    [yes, no].each do |badge|
      assert_match(/rounded-full/, badge)
      assert_match(/text-xs/, badge)
    end
  end

  test "boolean_badge distinguishes true from false by tone" do
    yes_classes = boolean_badge(true)[/class="([^"]*)"/, 1]
    no_classes = boolean_badge(false)[/class="([^"]*)"/, 1]

    assert_not_equal yes_classes, no_classes
  end

  # `sort_link` and `sort_icon` are not in `AdminHelper` any more - they were defined identically here and
  # in `ApplicationHelper`, so which copy answered depended on include order. The unit tests for `sort_icon`
  # moved to `application_helper_test`, and `sort_link` is tested inside a request, where it works:
  # `test/controllers/admin/sort_link_test.rb`. It was once skipped as "broken due to routing issues" with
  # `No route matches {direction: "desc", sort: :name}` kept in a comment; nothing was broken, an
  # ActionView::TestCase simply has no current page for those parameters to hang off.
end
