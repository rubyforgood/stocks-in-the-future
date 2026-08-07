# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module AdminHelper
  # Admin button classes, named once instead of repeated as a long literal on every page.
  # The literals they replaced had no focus style at all, so keyboard focus was invisible on
  # every admin action. The ring colour is always named, because Tailwind v4 resolves an
  # unset ring/outline colour to currentColor.
  #
  # h-10 (40px), matching design.md's button height token and the .tw-btn-* classes. This
  # first shipped as min-h-11 (44px) on the strength of the "minimum 44px touch targets"
  # note, which made every admin button visibly taller than the rest of the app. 40px is
  # what the design system specifies - the mainstream medium-button height, per Material 3,
  # Chakra and shadcn - and it clears WCAG 2.5.8 (AA), which asks for 24x24. The 44px figure
  # is AAA / Apple HIG.
  #
  # gap-2 rather than per-icon margins, so a leading icon needs no -ml-1 mr-2 of its own.
  # Admin uses the same three button classes as the app side. These are thin aliases so the
  # eleven call sites that ask for a class name keep working.
  #
  # They used to build their own strings from an ADMIN_BUTTON_BASE constant - a second base for
  # the same product, kept in step by hand, which it was not: the base omitted `justify-center`,
  # the primary carried a `border border-transparent` that design.md rules out by name, the
  # outlined pair used `border-slate-300` against the spec's `slate-200`, and none of them used
  # the `font-semibold` the filled variant is supposed to have. Two bases is the drift mechanism,
  # so there is one now, in buttons.css.
  def admin_primary_button_class
    "tw-btn-primary"
  end

  def admin_secondary_button_class
    "tw-btn-secondary"
  end

  # design.md's :danger_outline - slate at rest like :secondary, rose only on hover, because it
  # sits among bordered buttons.
  def admin_danger_button_class
    "tw-btn-danger-outline"
  end

  # Renders a table for index pages with sortable columns
  # @param collection [ActiveRecord::Relation] The records to display
  # @param columns [Array<Hash>] Column definitions with :attribute, :label, :sortable keys
  # @param options [Hash] Additional options for the table
  # The table card holds the table only. A page title and its actions belong at page
  # level, so they are rendered by components/ui/_page_header above this, not passed in.
  def admin_table(collection, columns: [], **options)
    render "admin/shared/table",
           collection: collection,
           columns: columns,
           options: options
  end

  # Renders attribute rows for show pages
  # @param resource [ActiveRecord::Base] The record to display
  # @param attributes [Array<Symbol>] Attributes to display
  def admin_show_attributes(resource, attributes: [])
    render "admin/shared/show_attributes", resource: resource, attributes: attributes
  end

  # Renders breadcrumbs for navigation
  # @param breadcrumbs [Array<Hash>] Breadcrumb items with :label and :path keys
  def admin_breadcrumbs(breadcrumbs = [])
    render "admin/shared/breadcrumbs", breadcrumbs: breadcrumbs
  end

  # Renders action buttons (Edit, Delete, Custom)
  # @param resource [ActiveRecord::Base] The record for actions
  # @param actions [Array<Symbol>] Actions to include (:edit, :delete, :custom)
  # @param custom_actions [Array<Hash>] Custom action definitions
  def admin_actions(resource, actions: %i[edit delete], custom_actions: [])
    render "admin/shared/actions", resource: resource, actions: actions, custom_actions: custom_actions
  end

  # Formats an attribute value for display
  # @param resource [ActiveRecord::Base] The record
  # @param attribute [Symbol] The attribute name
  # @return [String] Formatted value
  def format_attribute(resource, attribute)
    value = resource.send(attribute)

    case value
    when TrueClass, FalseClass
      boolean_badge(value)
    when Time, DateTime, Date
      value.strftime("%B %d, %Y")
    when ActiveRecord::Base
      format_association(value)
    when nil
      # slate-400 measures 2.6:1 on white and fails AA. slate-500 is 4.76:1 and
      # still reads as an absent value. Matches the em-dash markers in the views.
      content_tag(:span, "—", class: "text-slate-500")
    when %r{\Ahttps?://}
      format_url(value)
    else
      value.to_s
    end
  end

  # A URL in a dense table shows its host and links to the whole thing.
  #
  # Printed in full it was the widest cell in the app: admin/stocks carried a 267px
  # "https://www.verizon.com/..." in a `whitespace-nowrap` cell, which was the entire reason that
  # table still overflowed a Chromebook by 38px after every other column had been dealt with. The
  # host is the part an admin reads to confirm the right company; the rest is noise they can click.
  # Stripe, Linear and GitHub all shorten a URL to its host in a table.
  #
  # The full URL stays available to assistive tech through the title and the href, so nothing is
  # lost - and an invalid one falls back to printing what is there rather than raising.
  def format_url(value)
    host = begin
      URI.parse(value).host&.delete_prefix("www.")
    rescue URI::InvalidURIError
      nil
    end
    return value.to_s if host.blank?

    link_to host, value, class: "tw-link", title: value, rel: "noopener", target: "_blank"
  end

  # Renders a boolean badge
  # @param value [Boolean] The boolean value
  # @return [String] HTML badge
  def boolean_badge(value)
    if value
      render("components/ui/badge", label: "Yes", tone: :success)
    else
      render("components/ui/badge", label: "No", tone: :neutral)
    end
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

  # Renders search and filter form
  # @param filters [Array<Hash>] Filter definitions with :name, :label, :options keys
  # @param search_placeholder [String] Placeholder text for search field
  def admin_search_filter(filters: [], search_placeholder: "Search...")
    render "admin/shared/search_filter", filters: filters, search_placeholder: search_placeholder
  end

  # Determines the current discard filter state based on query parameters
  # @return [Symbol] :active, :discarded, or :all
  def current_discard_filter
    if params[:discarded].present?
      :discarded
    elsif params[:all].present?
      :all
    else
      :active
    end
  end

  # Returns the correct model for routing purposes
  # Handles STI (Single Table Inheritance) by returning the base class
  # @param record [ActiveRecord::Base] The record
  # @return [ActiveRecord::Base] The record or its base class for routing
  def route_model(record)
    if record.class.base_class == record.class
      record
    else
      record.becomes(record.class.base_class)
    end
  end

  # Renders the archive/activate toggle button for a classroom
  # @param classroom [Classroom] The classroom record
  # @return [String] HTML button
  def classroom_archive_toggle_button(classroom)
    if classroom.archived?
      activate_button(classroom)
    else
      archive_button(classroom)
    end
  end

  # Renders the discard/restore action button for a soft-deletable resource
  # @param resource [ActiveRecord::Base] The resource record (must respond_to :discarded?)
  # @return [String] HTML button or link
  def discard_restore_action(resource)
    if resource.discarded?
      restore_button(resource)
    else
      discard_link(resource)
    end
  end

  # Returns the appropriate show path for a user based on their type
  # @param user [User] The user record
  # @return [String] Path to the type-specific show page
  def user_show_path(user)
    case user.type
    when "Student"
      admin_student_path(user)
    when "Teacher"
      admin_teacher_path(user)
    else
      admin_user_path(user)
    end
  end

  private

  def format_association(value)
    # Use presenter if available, otherwise fall back to to_s
    presenter_class = "#{value.class.name}Presenter".safe_constantize
    display_value = if presenter_class
                      presenter_class.new(value).display_name
                    else
                      value.to_s
                    end

    # Try to link to the resource, but fall back to text if route doesn't exist
    begin
      link_to display_value, [:admin, route_model(value)]
    rescue NoMethodError, ActionController::UrlGenerationError
      display_value
    end
  end

  # Both of these are row actions, so they are ghosts like every other row action. Restore was
  # green-600 on white, which measures 3.30:1 and failed AA outright.
  def restore_button(resource)
    resource_name = resource.class.name.underscore
    restore_path = send("restore_admin_#{resource_name}_path", resource)

    ghost_action_button "Restore", restore_path,
                        icon: "rotate-ccw",
                        method: :patch,
                        data: { turbo_confirm: "Restore this #{resource_name.humanize.downcase}?" },
                        form: { class: "inline-flex" }
  end

  def discard_link(resource)
    resource_name = resource.class.name.underscore
    resource_path = send("admin_#{resource_name}_path", resource)

    ghost_action_link "Archive", resource_path,
                      icon: "archive", variant: :danger,
                      data: { turbo_method: :delete,
                              turbo_confirm: "Archive this #{resource_name.humanize.downcase}? " \
                                             "They will lose access, but their data is preserved." }
  end

  # This and archive_button sit in the classrooms#show toolbar between a bordered Edit and a
  # bordered Delete, so they are bordered too rather than ghosts.
  #
  # Both used to draw their icon with `content_tag(:i, class: "fas fa-*")`. The font-awesome
  # stylesheet is not linked in either layout, so those two elements rendered an empty <i> with no
  # glyph - an icon that was never once visible. They were also the only Font Awesome references
  # left in the app, and off-palette besides (green-300/yellow-300 borders, rounded-md at py-2
  # rather than the 40px h-10 token).
  def activate_button(classroom)
    link_to toggle_archive_admin_classroom_path(classroom),
            data: { turbo_method: :patch, turbo_confirm: "Activate #{classroom.name}?" },
            class: admin_secondary_button_class do
      safe_join(
        [
          lucide_icon("circle-check", class: "h-5 w-5 shrink-0 text-slate-500"),
          "Activate"
        ]
      )
    end
  end

  def archive_button(classroom)
    link_to toggle_archive_admin_classroom_path(classroom),
            data: { turbo_method: :patch,
                    turbo_confirm: "Archive #{classroom.name}? Teachers and students will no " \
                                   "longer be able to access it, but all historical data is preserved." },
            class: admin_danger_button_class do
      safe_join(
        [
          lucide_icon("archive", class: "h-5 w-5 shrink-0"),
          "Archive"
        ]
      )
    end
  end
end
# rubocop:enable Metrics/ModuleLength
