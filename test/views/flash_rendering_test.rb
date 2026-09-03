# frozen_string_literal: true

require "test_helper"

# The layouts render the flash. A view that renders it as well produces two
# copies of every message, under duplicate DOM ids, on the pages that do it.
class FlashRenderingTest < ActiveSupport::TestCase
  LAYOUTS = Rails.root.join("app/views/layouts").to_s

  # `notice`/`alert` used as helpers, not the words in class names or copy.
  FLASH_HELPER = /<%=\s*(notice|alert)\s*%>|\b(notice|alert)\.present\?|\bflash\[/

  test "only the layouts render flash messages" do
    offenders = Rails.root.glob("app/views/**/*.erb")
      .reject { |path| path.to_s.start_with?(LAYOUTS) }
      .select { |path| path.read.match?(FLASH_HELPER) }
      .map { |path| path.relative_path_from(Rails.root).to_s }
      .sort

    assert_empty offenders, <<~MESSAGE
      These views render the flash that the layouts already render, so their
      messages appear twice:

        #{offenders.join("\n        ")}

      Delete the flash markup from the view and let the layout render it.
    MESSAGE
  end
end
