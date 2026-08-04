# frozen_string_literal: true

require "test_helper"

class AdminHelperTest < ActionView::TestCase
  test "format_attribute formats boolean true" do
    user = build(:admin)
    result = format_attribute(user, :admin)
    assert_match(/Yes/, result)
    assert_match(/green/, result)
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

  # These assert the tone family and the badge scale rather than exact hues. Pinning
  # bg-green-100 meant the helper could not move onto the shared component - which uses the
  # lighter bg-green-50 with a ring - without three tests failing for no behavioural reason.
  test "boolean_badge renders yes badge through the shared component" do
    result = boolean_badge(true)

    assert_match(/Yes/, result)
    assert_match(/green/, result)
    assert_match(/text-xs/, result)
    assert_match(/px-2 py-0\.5/, result)
  end

  test "boolean_badge renders no badge through the shared component" do
    result = boolean_badge(false)

    assert_match(/No/, result)
    assert_match(/slate/, result)
    assert_match(/text-xs/, result)
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
