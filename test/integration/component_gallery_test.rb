# frozen_string_literal: true

require "test_helper"

# Every shared component appears in the gallery.
#
# `design-instructions.md` has said twice, for as long as the gallery has existed, to register new
# components there. It rendered **three of eleven** - `_callout`, `_page_header`, and `_badge` only
# incidentally, through `boolean_badge` - because nothing enforced the instruction. Eight components
# were built and none of them was registered, including several added while that instruction was being
# read.
#
# So the list is derived from the directory rather than kept by hand here: adding a partial and not
# adding a section fails, by name, with the testid to add.
class ComponentGalleryTest < ActionDispatch::IntegrationTest
  # `_page_header` renders `content_for :own_heading`, and `_stat`/`_icon_tile` take no block - the
  # gallery has to render each in whatever way it actually takes, which is the point of showing it.
  COMPONENTS = Rails.root.glob("app/views/components/ui/_*.html.erb")
    .map { |path| File.basename(path, ".html.erb").delete_prefix("_") }
    .sort.freeze

  setup { sign_in(create(:admin)) }

  test "the directory is not empty, so this test cannot pass by finding nothing" do
    assert_operator COMPONENTS.size, :>=, 8, "expected the shared components to be found on disk"
  end

  test "every component in app/views/components/ui has a section in the gallery" do
    get admin_component_demo_index_path

    assert_response :success
    body = response.parsed_body

    missing = COMPONENTS.reject do |component|
      body.at_css("[data-testid='component-#{component.tr('_', '-')}']")
    end

    assert_empty missing,
                 "not registered in the component gallery: #{missing.join(', ')}. Add a section to " \
                 "admin/component_demo/index with data-testid=\"component-<name>\"."
  end

  test "each section actually renders its component, rather than only naming it" do
    get admin_component_demo_index_path

    assert_response :success
    body = response.parsed_body

    COMPONENTS.each do |component|
      section = body.at_css("[data-testid='component-#{component.tr('_', '-')}']")
      next unless section

      # A heading, a sentence saying what it is for, and something rendered beneath them.
      assert section.at_css("h2"), "#{component}: the section has no heading"
      assert section.at_css("p"), "#{component}: the section does not say what the component is for"
      assert_operator section.text.length, :>, 80, "#{component}: the section looks empty"
    end
  end

  test "the gallery renders no database records, so it does not depend on what is seeded" do
    get admin_component_demo_index_path

    assert_response :success
    # The component sections are built from constructed data. The older admin-helper demos below them
    # still list real users, which is what the environment banner warns about.
    response.parsed_body.css("[data-testid^='component-']").each do |section|
      assert_not_includes section.text, "@example.com",
                          "a component section is rendering a real record's email"
    end
  end
end
