# frozen_string_literal: true

require "test_helper"

# `ApplicationHelper#sort_link`, tested where it works. It was defined identically in `AdminHelper` as well,
# so which copy answered depended on helper include order; there is one now.
#
# Two tests for this were skipped as "broken due to routing issues", their bodies commented out, with the
# error preserved in a comment: `No route matches {direction: "desc", sort: :name}`. Nothing was broken.
# The helper calls `url_for(sort:, direction:, only_path: true)`, which builds a URL relative to the
# **current page** - and a view test has no current page for those parameters to hang off. So the helper
# was fine and the test was in the wrong file for four skipped assertions.
module Admin
  class SortLinkTest < ActionDispatch::IntegrationTest
    setup { sign_in(create(:admin)) }

    def sort_href(label)
      link = response.parsed_body.css("th a").find { |a| a.text.strip.start_with?(label) }

      assert link, "no sort link labelled #{label}"
      link["href"]
    end

    test "a column that is not sorted offers ascending" do
      create(:student, :with_portfolio, classroom: create(:classroom))

      get admin_students_path

      assert_response :success
      assert_match(/sort=username/, sort_href("Username"))
      assert_match(/direction=asc/, sort_href("Username"))
    end

    test "the sorted column offers the other direction" do
      create(:student, :with_portfolio, classroom: create(:classroom))

      get admin_students_path(sort: "username", direction: "asc")

      assert_response :success
      # Ascending now, so the link toggles to descending.
      assert_match(/direction=desc/, sort_href("Username"))
    end

    test "a descending column offers ascending again, so the toggle is a toggle" do
      create(:student, :with_portfolio, classroom: create(:classroom))

      get admin_students_path(sort: "username", direction: "desc")

      assert_response :success
      assert_match(/direction=asc/, sort_href("Username"))
    end

    test "another column still offers ascending, whatever the sorted one is doing" do
      create(:student, :with_portfolio, classroom: create(:classroom))

      get admin_students_path(sort: "username", direction: "asc")

      assert_response :success
      assert_match(/direction=asc/, sort_href("Created at"))
    end

    # **The filter has to survive the sort.** `url_for(sort:, direction:)` rebuilds the path from the current
    # controller and action and drops every other query parameter, so sorting the archived list returned the
    # active one - a filter that silently reverts when you order the rows. Reproduced on both filters that
    # exist, plus the transactions list's own.
    test "sorting a filtered list keeps the filter" do
      create(:student, :discarded, classroom: create(:classroom))

      get admin_students_path(discarded: true)

      assert_response :success
      assert_match(/discarded=true/, sort_href("Username"))
      assert_match(/sort=username/, sort_href("Username"))
    end

    test "sorting an all-records list keeps that too" do
      create(:student, classroom: create(:classroom))

      get admin_students_path(all: true)

      assert_response :success
      assert_match(/all=true/, sort_href("Username"))
    end

    test "sorting one student's transactions keeps the student" do
      student = create(:student, :with_portfolio, classroom: create(:classroom))
      student.reload
      create(:portfolio_transaction, :deposit, portfolio: student.portfolio, amount_cents: 500)

      get admin_portfolio_transactions_path(user_id: student.id)

      assert_response :success
      assert_match(/user_id=#{student.id}/, sort_href("Amount"))
    end

    test "the link keeps the page it is on, rather than sending an admin somewhere else" do
      create(:teacher)

      get admin_teachers_path

      assert_response :success
      assert_match(%r{\A/admin/teachers\?}, sort_href("Email"))
    end
  end
end
