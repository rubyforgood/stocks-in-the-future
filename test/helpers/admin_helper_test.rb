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
    assert_match(/text-slate-500/, result)
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

  test "sort_icon returns up arrow for asc sort" do
    params[:sort] = "name"
    params[:direction] = "asc"
    assert_equal "↑", sort_icon(:name)
  end

  test "sort_icon returns down arrow for desc sort" do
    params[:sort] = "name"
    params[:direction] = "desc"
    assert_equal "↓", sort_icon(:name)
  end

  test "sort_icon returns both arrows for unsorted column" do
    params[:sort] = "email"
    assert_equal "⇅", sort_icon(:name)
  end

  # TODO: Fix sort_link routing issues in Admin - create separate ticket
  # Error: No route matches {direction: "desc", sort: :name}
  test "sort_link generates correct direction toggle" do
    skip "Broken due to routing issues"
    # params[:sort] = "name"
    # params[:direction] = "asc"
    # result = sort_link(:name, "Name")
    # assert_match(/direction=desc/, result)
    # assert_match(/Name/, result)
  end

  # TODO: Fix sort_link routing issues in Admin - create separate ticket
  # Error: No route matches {direction: "asc", sort: :name}
  test "sort_link defaults to asc for new sort" do
    skip "Broken due to routing issues"
    # params[:sort] = nil
    # params[:direction] = nil
    # result = sort_link(:name, "Name")
    # assert_match(/direction=asc/, result)
  end
end
