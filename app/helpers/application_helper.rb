# frozen_string_literal: true

module ApplicationHelper
  # Status tone for an order, so the two places that render one agree. Presentation lives in a
  # helper rather than the model - see design.md on the court-order pill.
  def order_status_tone(order)
    case order.status
    when "pending" then :warning
    when "completed" then :success
    when "canceled" then :danger
    else :neutral
    end
  end

  # Shown under the name in the account menu, so it is obvious which kind of account is
  # signed in. Admin is checked first because an admin is also a User by type.
  # The portfolio's comparison line, or nil when there is nothing to compare against.
  #
  # Three cases: no baseline at all (a student's first month), a baseline of zero (started from
  # nothing, so a percentage would divide by zero), and a normal comparison. The sign is explicit
  # because the direction must not rest on the colour.
  def portfolio_change_label(insights)
    return nil unless insights.comparison?

    amount = number_to_currency(insights.change_cents.abs / 100.0)
    sign = insights.change_up? ? "+" : "-"
    percent = insights.change_percent

    if percent.nil?
      "#{sign}#{amount} since last month"
    else
      "#{sign}#{amount} (#{number_with_precision(percent.abs, precision: 1)}%) since last month"
    end
  end

  # The app half's breadcrumb trail. Same partial as the admin half's, rooted at Home rather than the
  # dashboard - see `shared/_breadcrumbs`, which drops itself below two crumbs so a top-level page needs no
  # guard at the call site.
  #
  # The app half had no trail at all until a reader reported being unable to get back from a portfolio, and
  # it was not only that page: a stock, a classroom, a grade book and a student form are all reached *from*
  # somewhere and none of them said where.
  # `root:` because one page is reached from both halves. An admin opens a portfolio from the student's
  # admin record, so their trail roots at the dashboard and every crumb in it goes back where they were; a
  # teacher opens the same page from their classroom roster, and theirs roots at Home. Rooting both at Home
  # would give the admin a first crumb that is not on their path.
  # `Array(crumbs)` because a failed save re-renders `new` or `edit` from `create` or `update`, and a
  # controller that forgets to rebuild `@breadcrumbs` there hands this nil. That was a 500 on the invalid
  # branch of the classroom form - a page that renders fine until somebody submits it empty - so the trail
  # degrades to nothing rather than taking the page down. The branches below rebuild it anyway.
  def page_breadcrumbs(crumbs = [], root: :app)
    label, path = root == :admin ? ["Dashboard", admin_root_path] : ["Home", root_path]

    render "shared/breadcrumbs", breadcrumbs: Array(crumbs),
                                 root_label: label, root_path_for_trail: path
  end

  def account_role_label(user)
    return "Admin" if user.admin?
    return "Teacher" if user.teacher?
    return "Student" if user.student?

    "Account"
  end

  # portfolio_stocks.shares is decimal(15,2), so a sum comes back as a BigDecimal and rendered
  # straight it reads "3.0" - which it did on every trading-floor row and in the portfolio holdings
  # table. Truncating to an integer would be wrong, because the column really can hold a fraction;
  # stripping insignificant zeros gives "3" for 3.0 and keeps "1.5" as 1.5.
  def share_count(shares)
    number_with_precision(shares.to_d, precision: 2, strip_insignificant_zeros: true)
  end

  # The figure and its noun, agreeing. `share_count` formats the number and nothing was pluralising the
  # word beside it, so a single share read "1 shares". `pluralize` cannot be used directly: it would
  # print the raw BigDecimal, losing the precision and the stripped zeros - and a fractional holding is
  # plural, so only exactly one is singular.
  def shares_label(shares)
    "#{share_count(shares)} #{shares.to_d == 1 ? 'share' : 'shares'}"
  end

  # Up, down, flat - three states, and the colour is never the only signal (the sign and the arrow carry
  # the direction as well). The ticker this replaced tested `>= 0`, so an unchanged price was green with an
  # upward arrow; in a database where nothing has a yesterday price that was every row.
  #
  # green-700 and red-700, not the green-up/destructive pair in app/assets/stylesheets/application.css:
  # measured on white those two are 2.74:1 and 3.78:1 and fail AA, while these are 4.95:1 and 6.42:1.
  def movement_class(change)
    if change.positive?
      "text-green-700"
    elsif change.negative?
      "text-red-700"
    else
      "text-slate-600"
    end
  end

  def format_money(cents)
    format("$%.2f", cents / 100.0)
  end

  def safe_url(url)
    uri = URI.parse(url)
    %w[http https].include?(uri.scheme) ? url : nil
  rescue URI::InvalidURIError
    nil
  end

  # Generates a sort link for table headers
  # @param column [Symbol] The column name
  # @param label [String] The display label
  # @return [String] HTML link
  def sort_link(column, label)
    direction = params[:sort] == column.to_s && params[:direction] == "asc" ? "desc" : "asc"
    icon = sort_icon(column)

    # **Keeps whatever the reader is already looking at.** This was `url_for(sort:, direction:)`, which
    # rebuilds the path from the current controller and action and drops every other query parameter - so
    # sorting `/admin/students?discarded=true` silently returned the *active* list, and sorting a
    # transactions list filtered to one student returned everybody's. Every admin index with a filter had
    # it, and it is invisible until you sort a filtered page and read the rows.
    sort_params = request.query_parameters.symbolize_keys.merge(
      sort: column, direction: direction, only_path: true
    )
    url = url_for(sort_params)

    link_to url, class: "group inline-flex items-center" do
      safe_join(
        [
          label,
          content_tag(
            :span, icon,
            class: "ml-2 flex-none rounded text-slate-900 group-hover:text-slate-900"
          )
        ]
      )
    end
  end

  # Returns the sort icon for a column
  # @param column [Symbol] The column name
  # @return [String] Icon HTML
  def sort_icon(column)
    if params[:sort] == column.to_s
      params[:direction] == "asc" ? "↑" : "↓"
    else
      "⇅"
    end
  end
end
