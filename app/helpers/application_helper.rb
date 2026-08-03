# frozen_string_literal: true

module ApplicationHelper
  # Shown under the name in the account menu, so it is obvious which kind of account is
  # signed in. Admin is checked first because an admin is also a User by type.
  def account_role_label(user)
    return "Admin" if user.admin?
    return "Teacher" if user.teacher?
    return "Student" if user.student?

    "Account"
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
