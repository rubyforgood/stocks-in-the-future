# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
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
end
