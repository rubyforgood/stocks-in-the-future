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

  # The way back from a portfolio somebody else owns.
  #
  # A portfolio is a top-level destination for the student who owns it - the nav gets them there and back -
  # but a teacher and an admin arrive from a *record*: an admin from `admin/students#show`, whose
  # "View portfolio" button is the only link out of that page, and a teacher from their classroom roster,
  # where a student's name is the link. Neither had a way back. The page renders in the app layout, which
  # has no breadcrumb trail, so the browser's Back button was it.
  #
  # A back link rather than a trail, because that is this half's convention - `stocks#show` has
  # "Back to trading floor" in the same slot - and the destination is per role rather than per page,
  # because the two readers came from two different places.
  #
  # Returns nil for the owner, and for anyone whose origin cannot be named: a teacher can hold classrooms
  # in more than one school, but a student sits in exactly one, so `classroom` is the only honest answer.
  def portfolio_back_link(portfolio, viewer)
    owner = portfolio.user
    return if viewer.blank? || owner == viewer

    if viewer.admin?
      # `user_show_path`, which maps a user to their own record page. `admin/users#show` links here as well
      # as `admin/students#show`, and both send an admin to the same place - `Portfolio#user_must_be_student`
      # means an owner is always a Student, so there is no second type to branch on. Written as a branch
      # first, and the model rejected the fixture that would have exercised it.
      link_to "Back to #{owner.display_name}", user_show_path(owner), class: "tw-btn-secondary"
    elsif viewer.teacher? && owner.classroom.present?
      link_to "Back to #{owner.classroom.name}", classroom_path(owner.classroom), class: "tw-btn-secondary"
    end
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
