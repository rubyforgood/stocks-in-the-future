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

  def ticker_stocks
    Stock.active.order(:ticker)
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

    # Build URL with query parameters
    url = url_for(sort: column, direction: direction, only_path: true)

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
