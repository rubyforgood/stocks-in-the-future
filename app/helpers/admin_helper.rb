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
  # A teacher's state and reach, as the record page's summary line.
  #
  # The state was a badge under the title. It reads better as a sentence beside the other fact somebody wants -
  # how many classrooms they teach - and a page's summary is the place for a read-only fact that is not worth a
  # section. Whether they are active is stated in words, not only by a badge's colour.
  def teacher_summary(teacher)
    state = teacher.discarded? ? "Deactivated" : "Active"

    "#{state} · #{pluralize(teacher.classrooms.size, 'classroom')}"
  end

  # A student's account and what is in their portfolio, as the summary line. Nil-safe for the same reason as
  # the transaction helpers above: a failed save re-renders this page.
  #
  # **The username leads**, because the h1 is the student's name and the students list links by username -
  # without it here, clicking "jsmith2" would land on a page headed "Jordan Smith" with the identifier you
  # searched for nowhere above the fold except in a form field.
  #
  # The two money figures were `text-2xl` tiles in a four-across band, beside a third tile holding the
  # portfolio's **id**. This is the treatment the stock page already moved to: a read-only fact that is not
  # worth a section goes on the summary line. Shares held is not here - it is a holdings figure, and
  # "View portfolio" is one click away.
  def student_summary(student)
    parts = [student.username.presence, student.classroom&.name]

    if student.portfolio.present?
      parts << "#{number_to_currency(student.portfolio.cash_balance)} cash"
      parts << "#{number_to_currency(student.portfolio.total_portfolio_worth)} total value"
    end

    parts.compact.join(" · ").presence || "No classroom"
  end

  # What the transaction *is*, as its heading. An id is not a name - and this page already moved its id into
  # the breadcrumb once, for the same reason.
  # **Everything here tolerates a nil.** Now that view and edit are one page, a failed save re-renders the
  # record's own page - and an invalid record is one whose `portfolio_id`, type or amount is missing. This is
  # the second helper to learn it the hard way: `SchoolYear#name` raised from a page title while the form was
  # trying to show the validation message. Anything a merged page's header reads must survive an invalid
  # record.
  def transaction_title(transaction)
    return "Transaction" if transaction.transaction_type.blank? || transaction.amount_cents.blank?

    amount = number_to_currency(transaction.amount_cents / 100.0)

    "#{transaction.transaction_type.humanize} of #{amount}"
  end

  # The two facts the form cannot express: when the money moved, and the order that caused it. One line each,
  # so they belong in the summary rather than in sections of their own.
  def transaction_summary(transaction)
    parts = [transaction.portfolio&.user&.username,
             transaction.created_at && l(transaction.created_at.to_date, format: :long)]
    parts << "from order ##{transaction.order.id}" if transaction.order.present?

    parts.compact.join(" · ")
  end

  # A classroom's state and size, as its summary line. Archived and trading are **not** form fields - the
  # archive toggle is a header action and trading is the teacher's switch on their own classroom page - so they
  # are read-only facts, which is exactly what a summary line is for. Stated in words, not by colour alone.
  def classroom_summary(classroom)
    parts = [classroom.grades_display.presence, classroom.year_name.presence]
    parts << (classroom.trading_enabled? ? "trading on" : "trading off")
    parts << "archived" if classroom.archived?

    parts.compact.join(" · ")
  end

  # A user's role and where they sit, as the summary line. The two record pages without one were `users` and
  # `announcements`, which made them the odd pages out of nine - a summary line is where a read-only fact that
  # is not worth a section goes, and for a user the role is exactly that.
  #
  # `account_role_label` rather than `type`: an admin is a `User` row with `admin: true`, so the STI column
  # reads "User" for the one account that can do everything.
  def user_summary(user)
    parts = [account_role_label(user), user.classroom&.name]
    parts << "archived" if user.discarded?

    parts.compact.join(" · ")
  end

  # An announcement's state, which is the only thing about it that changes what anybody sees: exactly one is
  # featured, and that is the one rendered on the home page.
  def announcement_summary(announcement)
    return "Featured - shown on everyone's home page" if announcement.featured?

    "Not featured, so nobody sees it"
  end

  # A school year's summary: how many classrooms run in it, and the quarter count that used to be a card of
  # four identical rows.
  def school_year_summary(school_year)
    "#{pluralize(school_year.classrooms.size, 'classroom')} · " \
      "#{pluralize(school_year.quarters.size, 'quarter')}"
  end

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

  # `sort_link` and `sort_icon` are **not** here. They were defined identically in this module and in
  # ApplicationHelper - and since Rails mixes every helper into the same view context, which copy answered
  # depended on include order. One definition, in ApplicationHelper, which both halves of the product use.

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
                        data: { turbo_confirm: "Restore this #{resource_name.humanize.downcase}?\n\n" \
                                               "They can sign in again and reappear in the lists " \
                                               "they belong to. Nothing they did while archived " \
                                               "has changed." },
                        form: { class: "inline-flex" }
  end

  def discard_link(resource)
    resource_name = resource.class.name.underscore
    resource_path = send("admin_#{resource_name}_path", resource)

    ghost_action_link "Archive", resource_path,
                      icon: "archive", variant: :danger,
                      data: { turbo_method: :delete,
                              turbo_confirm: "Archive this #{resource_name.humanize.downcase}?\n\n" \
                                             "They lose access immediately and leave this list. " \
                                             "Everything attached to the account is kept, and an " \
                                             "administrator can restore it." }
  end

  # This and archive_button sit in the classrooms#show toolbar between a bordered Edit and a
  # bordered Delete, so they are bordered too rather than ghosts.
  #
  # Both used to draw their icon with `content_tag(:i, class: "fas fa-*")`. The font-awesome
  # stylesheet is not linked in either layout, so those two elements rendered an empty <i> with no
  # glyph - an icon that was never once visible. They were also the only Font Awesome references
  # left in the app, and off-palette besides (green-300/yellow-300 borders, rounded-md at py-2
  # rather than the 40px h-10 token).
  # A portfolio transaction is not a record of a balance - the balance is **derived from** the
  # transactions, so deleting one moves a student's money. That is the consequence worth stating, and the
  # old message ("Delete this deposit of $5.00 for ada? This cannot be undone.") did not.
  def transaction_delete_confirm(transaction)
    amount = number_to_currency(transaction.amount_cents / 100.0)
    direction = transaction.transaction_type.in?(%w[deposit credit]) ? "fall" : "rise"

    "Delete this #{transaction.transaction_type} of #{amount}?\n\n" \
      "#{transaction.portfolio.username}'s cash balance is worked out from their transactions, so it " \
      "will #{direction} by #{amount} as soon as this goes. This cannot be undone."
  end

  # A school year owns its four quarters, and those refuse to go while grade books hang off them
  # (`Quarter has_many :grade_books, dependent: :restrict_with_error`), as does the school year itself
  # while it has classrooms. So the honest message says what will happen *and* what will stop it.
  def school_year_delete_confirm(school_year)
    "Delete #{school_year.name}?\n\n" \
      "Its four quarters go with it. A school year that still has classrooms, or quarters with grade " \
      "books, cannot be deleted at all. This cannot be undone."
  end

  # The generic delete confirmation, for the three shared admin partials that each wrote their own -
  # `_actions` said "Are you sure you want to delete this classroom?", which names no record and gives no
  # basis for the decision, and the other two said the same thing in two more shapes.
  #
  # The body is deliberately about **what a delete is**, not about a particular model's cascade: this is
  # rendered for schools, school years, stocks, announcements and transactions, and a sentence claiming to
  # know what each one takes with it would be wrong somewhere. Where the cascade matters - a transaction
  # moving a balance, a school year taking its quarters - the call site passes its own.
  def delete_confirm(record)
    label = record.try(:name) || record.try(:username) || record.try(:title) || record.id

    "Delete #{record.class.model_name.human.downcase} \"#{label}\"?\n\n" \
      "It is removed permanently, along with anything that depends on it. This cannot be undone, and " \
      "there is no archived copy to restore from."
  end

  # The three teacher confirmations, written once - they appeared in three files with three different
  # sentences for the same two actions, and the delete one said only "Are you sure you want to
  # permanently delete this teacher?", which is the phrasing the confirmation dialog exists to replace.
  #
  # Deactivating **discards**: `User#destroy` is overridden to soft-delete, so nothing is lost.
  # `really_destroy!` is the one that is not, and only the delete action calls it - which is why these two
  # have to read differently rather than both saying "this cannot be undone".
  def teacher_deactivate_confirm(teacher)
    "Deactivate #{teacher.display_name}?\n\n" \
      "They lose access immediately and leave the active list. Their classrooms, the grades they " \
      "entered and everything else are kept, and you can reactivate them here."
  end

  def teacher_reactivate_confirm(teacher)
    "Reactivate #{teacher.display_name}?\n\n" \
      "They can sign in again and return to the active list, with the same classrooms they had."
  end

  def teacher_delete_confirm(teacher)
    "Permanently delete #{teacher.display_name}?\n\n" \
      "The account is removed for good, along with their assignment to any classroom. The classrooms " \
      "themselves and the grades they entered stay. This cannot be undone - deactivating keeps the " \
      "record and can be reversed."
  end

  # The archive/activate confirmations, written once. `activate_button` and `archive_button` render the
  # bordered toolbar version on classrooms#show, and the classrooms index repeats the pair as ghost row
  # actions - which is how the two came to carry differently worded copy for one action.
  def classroom_toggle_confirm(classroom)
    if classroom.archived?
      "Activate #{classroom.name}?\n\n" \
        "Its teachers and students can open it again, and trading returns to whatever the " \
        "classroom's own setting says."
    else
      "Archive #{classroom.name}?\n\n" \
        "Its teachers and students lose access immediately. Grades, portfolios and order history " \
        "are kept, and you can activate it again from this page."
    end
  end

  def activate_button(classroom)
    link_to toggle_archive_admin_classroom_path(classroom),
            data: { turbo_method: :patch, turbo_confirm: classroom_toggle_confirm(classroom) },
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
            data: { turbo_method: :patch, turbo_confirm: classroom_toggle_confirm(classroom) },
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
