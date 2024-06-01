require "administrate/base_dashboard"

class StockDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    cash_flow: Field::String.with_options(searchable: false),
    company_name: Field::String,
    company_website: Field::String,
    competitor_names: Field::Text,
    debt: Field::String.with_options(searchable: false),
    debt_to_equity: Field::String.with_options(searchable: false),
    description: Field::Text,
    employees: Field::Number,
    industry: Field::String,
    industry_avg_debt_to_equity: Field::String.with_options(searchable: false),
    industry_avg_profit_margin: Field::String.with_options(searchable: false),
    industry_avg_sales_growth: Field::String.with_options(searchable: false),
    management: Field::Text,
    portfolio_stocks: Field::HasMany,
    price_info: Field::String.with_options(searchable: false),
    profit_margin: Field::String.with_options(searchable: false),
    sales_growth: Field::String.with_options(searchable: false),
    stock_exchange: Field::String,
    ticker: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    cash_flow
    company_name
    company_website
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    cash_flow
    company_name
    company_website
    competitor_names
    debt
    debt_to_equity
    description
    employees
    industry
    industry_avg_debt_to_equity
    industry_avg_profit_margin
    industry_avg_sales_growth
    management
    portfolio_stocks
    price_info
    profit_margin
    sales_growth
    stock_exchange
    ticker
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    cash_flow
    company_name
    company_website
    competitor_names
    debt
    debt_to_equity
    description
    employees
    industry
    industry_avg_debt_to_equity
    industry_avg_profit_margin
    industry_avg_sales_growth
    management
    portfolio_stocks
    price_info
    profit_margin
    sales_growth
    stock_exchange
    ticker
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how stocks are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(stock)
  #   "Stock ##{stock.id}"
  # end
end
