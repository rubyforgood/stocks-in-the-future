# frozen_string_literal: true

require "test_helper"

class AdminV2HelperTest < ActionView::TestCase
  test "format_attribute formats boolean true" do
    user = build(:user, admin: true)
    result = format_attribute(user, :admin)
    assert_match(/Yes/, result)
    assert_match(/bg-green-100/, result)
  end

  test "format_attribute formats boolean false" do
    user = build(:user, admin: false)
    result = format_attribute(user, :admin)
    assert_match(/No/, result)
    assert_match(/bg-gray-100/, result)
  end

  test "format_attribute formats date" do
    date = Date.new(2025, 12, 22)
    user = build(:user, created_at: date)
    result = format_attribute(user, :created_at)
    assert_equal "December 22, 2025", result
  end

  test "format_attribute formats nil value" do
    user = build(:user, name: nil)
    result = format_attribute(user, :name)
    assert_match(/—/, result)
    assert_match(/text-gray-400/, result)
  end

  test "format_attribute formats string" do
    user = build(:user, email: "test@example.com")
    result = format_attribute(user, :email)
    assert_equal "test@example.com", result
  end

  test "boolean_badge renders yes badge" do
    result = boolean_badge(true)
    assert_match(/Yes/, result)
    assert_match(/bg-green-100/, result)
    assert_match(/text-green-800/, result)
  end

  test "boolean_badge renders no badge" do
    result = boolean_badge(false)
    assert_match(/No/, result)
    assert_match(/bg-gray-100/, result)
    assert_match(/text-gray-800/, result)
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

  test "sort_link generates correct direction toggle" do
    params[:sort] = "name"
    params[:direction] = "asc"
    result = sort_link(:name, "Name")
    assert_match(/direction=desc/, result)
    assert_match(/Name/, result)
  end

  test "sort_link defaults to asc for new sort" do
    params.clear
    result = sort_link(:name, "Name")
    assert_match(/direction=asc/, result)
  end
end
