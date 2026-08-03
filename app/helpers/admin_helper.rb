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
  ADMIN_BUTTON_BASE = "inline-flex h-10 items-center gap-2 px-4 shadow-sm text-sm " \
                      "font-medium rounded-lg focus-visible:outline-2 " \
                      "focus-visible:outline-offset-2"

  def admin_primary_button_class
    "#{ADMIN_BUTTON_BASE} border border-transparent text-white bg-sitf-primary " \
      "hover:bg-sitf-primary-dark focus-visible:outline-sitf-primary-dark"
  end

  def admin_secondary_button_class
    "#{ADMIN_BUTTON_BASE} border border-slate-300 text-slate-700 bg-white " \
      "hover:bg-slate-50 focus-visible:outline-sitf-primary"
  end

  def admin_danger_button_class
    "#{ADMIN_BUTTON_BASE} border border-red-300 text-red-700 bg-white hover:bg-red-50 " \
      "focus-visible:outline-red-700"
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
    else
      value.to_s
    end
  end

  # Renders a boolean badge
  # @param value [Boolean] The boolean value
  # @return [String] HTML badge
  def boolean_badge(value)
    if value
      content_tag(
        :span, "Yes",
        class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
      )
    else
      content_tag(
        :span, "No",
        class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800"
      )
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

  def restore_button(resource)
    resource_name = resource.class.name.underscore
    restore_path = send("restore_admin_#{resource_name}_path", resource)

    button_to "Restore", restore_path,
              method: :patch,
              data: { turbo_confirm: "Are you sure you want to restore this #{resource_name.humanize.downcase}?" },
              class: "text-green-600 hover:text-green-800",
              form: { style: "display: inline;" }
  end

  def discard_link(resource)
    resource_name = resource.class.name.underscore
    resource_path = send("admin_#{resource_name}_path", resource)

    link_to "Archive", resource_path,
            data: { turbo_method: :delete, turbo_confirm: "Are you sure you want to archive this #{resource_name.humanize.downcase}?" }, # rubocop:disable Layout/LineLength
            class: "text-red-600 hover:text-red-800"
  end

  def activate_button(classroom)
    button_class = "inline-flex items-center px-4 py-2 border border-green-300 shadow-sm " \
                   "text-sm font-medium rounded-md text-green-700 bg-white hover:bg-green-50"
    link_to toggle_archive_admin_classroom_path(classroom),
            data: { turbo_method: :patch, turbo_confirm: "Are you sure you want to activate this classroom?" },
            class: button_class do
      safe_join(
        [
          content_tag(:i, "", class: "fas fa-check-circle -ml-1 mr-2 h-5 w-5 text-green-500"),
          "Activate"
        ]
      )
    end
  end

  def archive_button(classroom)
    button_class = "inline-flex items-center px-4 py-2 border border-yellow-300 shadow-sm " \
                   "text-sm font-medium rounded-md text-yellow-700 bg-white hover:bg-yellow-50"
    link_to toggle_archive_admin_classroom_path(classroom),
            data: { turbo_method: :patch, turbo_confirm: "Are you sure you want to archive this classroom?" },
            class: button_class do
      safe_join(
        [
          content_tag(:i, "", class: "fas fa-archive -ml-1 mr-2 h-5 w-5 text-yellow-500"),
          "Archive"
        ]
      )
    end
  end
end
# rubocop:enable Metrics/ModuleLength
