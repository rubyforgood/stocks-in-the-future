# frozen_string_literal: true

require "test_helper"

# Every route under /admin turns away anyone who is not an admin.
#
# Authorization in this namespace is one `before_action` in `Admin::BaseController`, and nothing calls
# `authorize` per record - a `PortfolioTransactionsController` carried six commented-out `authorize` lines
# and a TODO asking whether it should, which is a question about the shape of the guarantee rather than
# about that controller.
#
# The answer is that the guarantee is fine and the **proof** was missing: `base_controller_test` checked
# `admin_root_path` and two controller tests checked one action each, out of about sixty. A superclass
# `before_action` is only as good as the evidence that no route skips it - a controller that inherits from
# `ApplicationController` by mistake, or a route mounted outside the namespace, looks identical until
# somebody signs in as a teacher.
#
# So this derives the list from the route table rather than a hand-kept one: a new admin route is covered
# the moment it exists.
class AdminAccessTest < ActionDispatch::IntegrationTest
  # GET routes only. A POST/PATCH/DELETE takes the same before_action - it runs before any action in the
  # namespace - and driving them needs valid params per controller, which would make this a test about
  # forms rather than about access.
  ADMIN_GETS = Rails.application.routes.routes.filter_map do |route|
    path = route.path.spec.to_s.sub("(.:format)", "")
    verb = route.verb
    next unless path.start_with?("/admin")
    next unless verb == "GET"
    next if path.include?(":") # needs an id; the id-less routes reach every controller already

    path
  end.uniq.freeze

  test "the route list is not empty, so this cannot pass by testing nothing" do
    assert_operator ADMIN_GETS.size, :>=, 8,
                    "expected the admin index and new routes: #{ADMIN_GETS.inspect}"
  end

  test "a teacher is turned away from every admin page" do
    sign_in(create(:teacher))

    ADMIN_GETS.each do |path|
      get path

      assert_redirected_to root_path, "a teacher reached #{path}"
      assert_equal "Access denied. Admin privileges required.", flash[:alert], "no alert for #{path}"
    end
  end

  test "a student is turned away from every admin page" do
    sign_in(create(:student, :with_portfolio, classroom: create(:classroom)))

    ADMIN_GETS.each do |path|
      get path

      assert_redirected_to root_path, "a student reached #{path}"
    end
  end

  test "a signed-out visitor is sent to sign in, not to the app root" do
    ADMIN_GETS.each do |path|
      get path

      assert_redirected_to new_user_session_path, "#{path} did not ask a stranger to sign in"
    end
  end

  test "an admin reaches them all" do
    sign_in(create(:admin))

    ADMIN_GETS.each do |path|
      get path

      assert_response :success, "an admin could not open #{path}"
    end
  end
end
