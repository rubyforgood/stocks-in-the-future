# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # Moved from `admin_helper_test` with the method itself: `sort_icon` and `sort_link` were defined twice,
  # identically, and both halves of the product read whichever copy the include order happened to pick.
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

  test "safe_url returns valid http URL" do
    url = "http://example.com"

    result = safe_url(url)

    assert_equal url, result
  end

  test "safe_url returns valid https URL" do
    url = "https://example.com"

    result = safe_url(url)

    assert_equal url, result
  end

  test "safe_url returns valid https URL with path and query" do
    url = "https://example.com/path?query=value"

    result = safe_url(url)

    assert_equal url, result
  end

  test "safe_url returns nil for javascript URL" do
    url = "javascript:alert('XSS')"

    result = safe_url(url)

    assert_nil result
  end

  test "safe_url returns nil for data URL" do
    url = "data:text/html,<script>alert('XSS')</script>"

    result = safe_url(url)

    assert_nil result
  end

  test "safe_url returns nil for invalid URL" do
    url = "not a valid url"

    result = safe_url(url)

    assert_nil result
  end

  test "safe_url returns nil for blank string" do
    result = safe_url("")

    assert_nil result
  end

  test "safe_url returns nil for nil" do
    result = safe_url(nil)

    assert_nil result
  end

  test "safe_url returns nil for ftp URL" do
    url = "ftp://example.com"

    result = safe_url(url)

    assert_nil result
  end

  test "safe_url returns nil for file URL" do
    url = "file:///etc/passwd"

    result = safe_url(url)

    assert_nil result
  end

  test "a single share is singular, and a fraction is not" do
    assert_equal "1 share", shares_label(1)
    assert_equal "2 shares", shares_label(2)
    assert_equal "0 shares", shares_label(0)
    assert_equal "1.5 shares", shares_label(1.5)
    assert_equal "0.5 shares", shares_label(0.5)
  end
end
