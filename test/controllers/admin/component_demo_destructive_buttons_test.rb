# frozen_string_literal: true

require "test_helper"

module Admin
  class ComponentDemoDestructiveButtonsTest < ActionDispatch::IntegrationTest
    # A page of hypothetical UI, on the subject of buttons that delete things. Live, it would read as
    # shipped product and its mock dialogs would read as real controls.
    test "the destructive buttons preview is not reachable outside development" do
      sign_in(create(:admin))

      get destructive_buttons_admin_component_demo_index_path

      assert_response :not_found
    end
  end
end
