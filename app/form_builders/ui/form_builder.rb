# frozen_string_literal: true

# The app's form builder, for both halves of the product.
#
# It was `Ui::FormBuilder`, and the name was the problem: the nine admin forms were built from it while
# the app half wrote its fields out by hand. The two agreed on tokens - tw-input-primary, tw-label-primary,
# 44px, p-5 - and disagreed on construction, which is the drift mechanism this codebase keeps
# rediscovering: four card paddings, two button bases, two definitions of a field message.
#
# Named for `app/views/components/ui/`, which is where the rest of the shared UI lives.
#
# The shape is label, hint, input, error - what GOV.UK, Polaris, Carbon and Material all specify, and the
# reason the admin forms read better than the hand-written ones.
module Ui
  # rubocop:disable Metrics/ClassLength
  class FormBuilder < ActionView::Helpers::FormBuilder
    # The named classes from forms.css, not a second set of strings. These were the app's
    # longest-standing field drift: rounded-md where the token is rounded-lg, a border faked with
    # ring-1 ring-inset, gray-* rather than slate-*, an off-brand blue-600 focus ring, an `sm:`
    # tier this app does not use, and `placeholder:text-gray-400` at **2.54:1** - a straight AA
    # failure on every placeholder in nine admin forms. tw-input-primary was written specifically
    # to fix all of that and this builder never adopted it.
    INPUT_CLASSES = "tw-input-primary"
    # The same native control components/ui/_checkbox renders: accent-sitf-primary rather than an
    # off-brand blue tick, a slate border, and a named focus ring.
    CHECKBOX_CLASSES = "size-4 shrink-0 rounded-sm border-slate-500 accent-sitf-primary " \
                       "focus-visible:outline-2 focus-visible:outline-offset-2 " \
                       "focus-visible:outline-sitf-primary"

    LABEL_TEXT_CLASSES = "min-w-0 text-sm font-medium text-slate-900"

    # **A short field is one column wide, and the fields still stack.** `width: :half` puts `.tw-field-half`
    # on the control - `max-width: calc(50% - 0.75rem)`, half the card's content box less half a gutter, so
    # 351px of 726px: the width the field would have *if* another sat beside it.
    #
    # It went through two wrong shapes first. Four fixed `max-w-*` sizes were GOV.UK's content-width rule
    # applied without its layout, and a 128px field above a 384px one aligns with nothing. A two-column grid
    # was the same instruction read as the indicative - "were there another field beside it" describes a
    # width, not a pairing - and it costs a second scan line down a form.
    #
    # On the control rather than the wrapper: the label and the hint keep the full measure, so a two-line
    # hint does not wrap into four. GOV.UK's width modifiers go on the input for the same reason.
    FIELD_WIDTHS = {
      half: "tw-field-half",
      full: nil
    }.freeze

    INPUT_ERROR_CLASSES = "tw-input-error"
    LABEL_CLASSES = "tw-label-primary"
    HINT_CLASSES = "tw-field-hint"

    # Override text_field to include Tailwind styling and error handling
    def text_field(attribute, options = {})
      field_wrapper(attribute, options) do
        super(attribute, input_options(attribute, options))
      end
    end

    # Email field with proper type and styling
    def email_field(attribute, options = {})
      field_wrapper(attribute, options) do
        super(attribute, input_options(attribute, options))
      end
    end

    # Password field
    def password_field(attribute, options = {})
      field_wrapper(attribute, options) do
        super(attribute, input_options(attribute, options))
      end
    end

    # Number field with optional step
    def number_field(attribute, options = {})
      field_wrapper(attribute, options) do
        options[:step] ||= "any" unless options.key?(:step)
        super(attribute, input_options(attribute, options))
      end
    end

    # A cents column shown and entered in dollars.
    # Usage: f.currency_field :price_cents, multiplier: 0.01, decimals: 2
    #
    # **One wrapper.** This used to call `field_wrapper` and then `number_field`, which wraps again - so every
    # currency field rendered **two** labels: the one it was given, then a second from the humanized attribute
    # name, because the first wrapper had already deleted `:label` from the options. Reported as "amount says
    # amount in dollars then there is another subheader amount cents", and it was on three fields across two
    # forms: Amount / "Amount cents", Current price / "Price cents", Yesterday's price / "Yesterday price
    # cents". Delegating to `number_field` leaves exactly one label, one hint and one message.
    def currency_field(attribute, options = {})
      multiplier = options.delete(:multiplier) || 0.01
      decimals = options.delete(:decimals) || 2
      value = object.public_send(attribute)

      number_field(
        attribute,
        options.merge(
          value: value ? (value * multiplier).round(decimals) : nil,
          step: (1.0 / (10**decimals))
        )
      )
    end

    # Text area with proper styling
    def text_area(attribute, options = {})
      field_wrapper(attribute, options) do
        options[:rows] ||= 4
        super(attribute, input_options(attribute, options))
      end
    end

    # Rich text area for ActionText fields
    def rich_text_area(attribute, options = {})
      field_wrapper(attribute, options) do
        options[:class] = "trix-content #{options[:class] || ''}"
        super(attribute, options)
      end
    end

    # Override select to support label and hint options
    def select(attribute, choices = nil, options = {}, html_options = {}, &)
      # Extract custom options if provided as hash (when called with label/hint)
      return super if choices.is_a?(Hash) && options.empty? && html_options.empty?
      return super unless options.is_a?(Hash) && (options.key?(:label) || options.key?(:hint))

      # Called as: select(:attr, choices, label: "...", hint: "...", include_blank: ...)
      render_select_with_wrapper(attribute, choices, options, html_options, &)
    end

    # Select field with collection
    # Usage: f.select_field :status, collection: [['Active', 'active'], ['Inactive', 'inactive']]
    # Usage: f.select_field :grade, collection: (1..12).map { |g| [g.ordinalize, g] }
    def select_field(attribute, options = {})
      collection = options.delete(:collection) || []
      include_blank = options.delete(:include_blank)

      field_wrapper(attribute, options) do
        select(
          attribute, collection,
          { include_blank: include_blank },
          input_options(attribute, options)
        )
      end
    end

    # Boolean field (checkbox) with proper styling
    # A lone checkbox - an opt-in, which is what GOV.UK reserves a single checkbox for.
    #
    # Same wrapped-label row as a group's item, so the two read alike, with the hint indented to the
    # label's text column rather than starting under the box: `pl-7` is the 16px box plus the 12px gap.
    # GOV.UK indents a checkbox's hint the same way, and it is what makes the sentence belong to that
    # option rather than to the form.
    def boolean_field(attribute, options = {})
      hint = options.delete(:hint)
      label_text = options.delete(:label) || attribute.to_s.humanize
      # Overridable like every other wrapper here, because a lone checkbox is not always a row in a
      # stack of fields - sign in puts one beside a link, on one line.
      wrapper_class = options.delete(:wrapper_class) || "mb-6"

      @template.content_tag(:div, class: wrapper_class) do
        @template.content_tag(:label, class: "flex items-center gap-3") do
          check_box(attribute, class: CHECKBOX_CLASSES) +
            @template.content_tag(:span, label_text, class: "#{LABEL_CLASSES} mb-0")
        end +
          (hint ? @template.content_tag(:p, hint, class: "mt-1 pl-7 text-sm text-slate-600") : "".html_safe)
      end
    end

    # Collection checkboxes with proper styling
    def collection_check_boxes(attribute, collection, value_method, text_method, options = {})
      label_text = options.delete(:label) || attribute.to_s.humanize
      hint = options.delete(:hint)
      wrapper_class = options.delete(:wrapper_class) || ""
      # Lay the boxes out in columns from `lg`, for a group whose labels are short and uniform. Fourteen
      # school years in one column measured 608px; three columns is 212px. GOV.UK and Polaris both allow a
      # multi-column checkbox group for exactly that shape, and both keep one column on a phone.
      columns = options.delete(:columns)

      # A group *does* need its own message: the proc skips checkboxes deliberately, because a group's error
      # belongs to the group and Rails would otherwise attach it to whichever box it rendered first. This is
      # `FormErrorsHelper#field_error`, the same call `classrooms/_form` makes for its fieldsets, so a group's
      # message and a field's are one component rather than two that drift.
      required = options.delete(:required)
      # The attribute the *errors* are on, which is not always the one the field posts. A classroom's
      # grades come in as `grade_ids` and the validation is on `grades`, so without this the fieldset is
      # never marked invalid and the group's message never renders - which is exactly what happened, and
      # what the hand-written fieldset it replaced got right by naming both.
      errors_on = options.delete(:errors_on) || attribute
      error_attrs = @template.field_error_attrs(object, errors_on)

      # `<fieldset>` with `aria-invalid` / `aria-describedby` from FormErrorsHelper, so assistive tech ties
      # the group to its message - the same call the hand-written fieldsets make.
      # No width option here: a group of checkboxes lays its own boxes out in columns and is never a short
      # field, so `width:` would only ever be wrong.
      @template.content_tag(:div, class: "mb-6 #{wrapper_class}") do
        @template.tag.fieldset(**error_attrs) do
          build_checkbox_collection_label(label_text, hint, required:) +
            build_checkbox_collection_items(attribute, collection, value_method, text_method, columns) +
            (@template.field_error(object, errors_on) || "".html_safe)
        end
      end
    end

    # Date field
    def date_field(attribute, options = {})
      field_wrapper(attribute, options) do
        super(attribute, input_options(attribute, options))
      end
    end

    # DateTime field
    def datetime_field(attribute, options = {})
      field_wrapper(attribute, options) do
        options[:class] = "#{input_class(attribute)} #{options[:class] || ''}"
        super(attribute, options)
      end
    end

    # Association select field (for BelongsTo associations)
    # Usage: f.association_select :classroom_id, collection: Classroom.all
    # Usage: f.association_select :school_year_id, collection: SchoolYear.all, label_method: :display_name
    def association_select(attribute, options = {})
      collection = options.delete(:collection)
      label_method = options.delete(:label_method) || :to_s
      value_method = options.delete(:value_method) || :id
      include_blank = options.delete(:include_blank) || "Select..."

      raise ArgumentError, "collection is required for association_select" unless collection

      choices = collection.map do |item|
        build_select_choice(item, label_method, value_method)
      end

      field_wrapper(attribute, options) do
        select(
          attribute, choices,
          { include_blank: include_blank },
          input_options(attribute, options)
        )
      end
    end

    # Read-only field (displays value, not an input)
    # Usage: f.read_only_field :created_at
    # Usage: f.read_only_field :total_amount, value: "$#{object.total_amount}"
    def read_only_field(attribute, options = {})
      label_text = options.delete(:label) || attribute.to_s.humanize
      value = options.delete(:value) || format_value(object.public_send(attribute))
      hint = options.delete(:hint)

      @template.content_tag(:div, class: "py-4") do
        @template.content_tag(:dt, label_text, class: "text-sm font-medium text-slate-600") +
          @template.content_tag(:dd, class: "mt-1 text-sm text-slate-900") do
            value.to_s.html_safe # rubocop:disable Rails/OutputSafety
          end +
          (hint ? @template.content_tag(:p, hint, class: HINT_CLASSES) : "".html_safe)
      end
    end

    # Both of these delegate to the shared button classes rather than hand-rolling a shape.
    #
    # submit_button backs eleven admin forms and was `bg-blue-600` - a generic Tailwind blue, not
    # the brand teal, at `rounded-md px-4 py-2` instead of the 40px `h-10 rounded-lg` token. So
    # every primary button on every admin form was off-brand and a different size from the primary
    # buttons in the page headers directly above them. cancel_button (ten forms) was the same
    # story in `gray-*`. This file sits in app/form_builders, which is why sweeps over app/views,
    # app/helpers and app/assets/tailwind never saw it - and Tailwind scans .rb, so it all
    # compiled and shipped.
    # variant: :secondary for a sub-form's submit. design.md, "One primary CTA per page": a view
    # gets exactly one filled primary - its main action - and an inline sub-form submit inside a
    # management card is secondary, never primary. admin/students#edit stacked "Update student"
    # with "Add transaction", which is the shape that rule exists to prevent.
    def submit_button(text = "Save", options = {})
      variant = options.delete(:variant) || :primary
      base = if variant.to_sym == :secondary
               @template.admin_secondary_button_class
             else
               @template.admin_primary_button_class
             end
      options[:class] = "#{base} #{options[:class]}".strip

      submit(text, options)
    end

    # Cancel button (link styled as button)
    def cancel_button(text = "Cancel", url:, options: {})
      options[:class] = "#{@template.admin_secondary_button_class} #{options[:class]}".strip

      @template.link_to(text, url, options)
    end

    # **Literal class strings, not interpolation.** Tailwind compiles what it can *see* in the source, and
    # it cannot see `lg:grid-cols-#{columns}` - so the first version of this rendered a grid with no columns
    # and the group was only short because three items fit anyway. Measured: `grid-template-columns` came
    # back as a single track. Anything that builds a class name from a variable has to spell the results out.
    # `gap-x` only, for the same reason the single-column layout has no `space-y`: the row's own `py-2` is
    # the vertical separation, and a grid `gap-2` would stack on it. The horizontal gutter is 24px, which is
    # the gutter `.tw-field-half` already assumes between two half-width fields.
    COLUMN_LAYOUTS = {
      2 => "mt-2 grid grid-cols-1 gap-x-6 lg:grid-cols-2",
      3 => "mt-2 grid grid-cols-1 gap-x-6 lg:grid-cols-3",
      4 => "mt-2 grid grid-cols-1 gap-x-6 lg:grid-cols-4"
    }.freeze

    private

    def build_select_choice(item, label_method, value_method)
      label = if label_method.respond_to?(:call)
                label_method.call(item)
              else
                item.public_send(label_method)
              end

      value = if value_method.respond_to?(:call)
                value_method.call(item)
              else
                item.public_send(value_method)
              end

      [label, value]
    end

    # Build checkbox collection label and hint
    # A `<legend>`, not a `<label>`.
    #
    # A label has to point at one control, and a group of checkboxes has no single control to point at -
    # so this rendered a label naming nothing, and the group had no accessible name at all. That is the
    # bug `classrooms/_form` was rebuilt to fix, by hand; it belongs here, where every group gets it.
    # GOV.UK, Polaris and Primer all use a fieldset for this.
    def build_checkbox_collection_label(label_text, hint, required: false)
      @template.content_tag(:legend, class: LABEL_CLASSES) do
        @template.safe_join([label_text, required_indicator(required)])
      end + (hint ? @template.content_tag(:p, hint, class: "#{HINT_CLASSES} mb-3") : "".html_safe)
    end

    # Build checkbox collection items
    def build_checkbox_collection_items(attribute, collection, value_method, text_method, columns = nil)
      # One empty value ahead of the boxes, so unchecking everything submits an empty list rather than
      # omitting the key - without it the parameter is simply absent and the record keeps what it had, so
      # clearing a group silently does nothing and reports a save that worked. `id: nil` because it would
      # otherwise take the same derived id as every checkbox below it.
      @template.hidden_field_tag("#{object_name}[#{attribute}][]", "", id: nil) +
        @template.content_tag(:div, class: checkbox_collection_layout(columns)) do
          collection.map do |item|
            build_single_checkbox(attribute, item, value_method, text_method)
          end.join.html_safe # rubocop:disable Rails/OutputSafety
        end
    end

    # `gap-2`, not `space-y-2`, in the grid case. `space-y-*` compiles to a rule on adjacent *siblings*
    # (`> :not([hidden]) ~ :not([hidden])`), which in a grid adds a top margin to every item that is not
    # first in **DOM** order rather than first in its row - so the columns come out ragged. The one-column
    # case keeps `space-y-2`, because that is what it has always rendered and there is nothing to change.
    # **The rows are contiguous, and the padding is the only gap.**
    #
    # This was `space-y-2` on top of `py-2` on each row: 8px of padding, an 8px gap, 8px of padding, so 24px
    # of air between one option's text and the next and a 60px pitch for a two-line row. Reported as too much
    # padding between the checkboxes, and it is - three spacings doing one job.
    #
    # design.md does not set a value here, so the field decides, and the row's own `hover:bg-slate-50` fill
    # is what settles it: a filled row is Primer's ActionList and Material's list item, both of which run
    # their rows edge to edge, because a gap between two fills reads as a hole rather than as separation.
    # Polaris's bare ChoiceList uses a gap and no padding - the other consistent answer, and not this
    # component. Measured after: 52px pitch for the two-line rows on the teacher form, 36px for a one-line
    # group, against GOV.UK's 54px and Material's 56px two-line item.
    def checkbox_collection_layout(columns)
      return "mt-2" if columns.blank?

      COLUMN_LAYOUTS.fetch(columns.to_i)
    end

    # Build a single checkbox item
    # `text_method` may be a symbol or a callable, the same latitude `build_select_choice` already gives a
    # select's label. A callable lets an item be more than one line - the teacher picker shows a name over
    # an email, because two teachers whose names begin with T are told apart by the email and nothing else
    # - without that group having to be written out by hand, which is how it came to be the one group in
    # the app with its own fieldset markup.
    # `text_method` may be a symbol or a callable, the same latitude `build_select_choice` already gives a
    # select's label. A callable lets an item be more than one line - the teacher picker shows a name over
    # an email, because two teachers whose names begin with T are told apart by the email and nothing else.
    #
    # **The whole row is the `<label>`**, with the box inside it, rather than a `for=` pointing across two
    # sibling divs. Both are valid, and GOV.UK does the latter - but wrapping makes the row's whole width a
    # hit target, which matters for students on phones, and it is the shape the app's own geometry tests
    # measure. No `px-*`: horizontal padding here pushes the box off the form's left edge, which was
    # reported once as the teacher checkbox looking misaligned - against the gutter, not its own label.
    def build_single_checkbox(attribute, item, value_method, text_method)
      value = item.send(value_method)
      text = text_method.respond_to?(:call) ? text_method.call(item) : item.send(text_method)
      checked = Array(object.send(attribute)).include?(value)

      # The weight goes on a plain label and **not** on a custom one. A callable supplies its own markup -
      # the teacher picker's name over an email - and a `font-medium` wrapper around both makes the email
      # fight it back with `font-normal`, a rule whose only job is to undo another rule. It also makes the
      # wrapper the thing that reads as "the label", when the label is its first line.
      text_class = text_method.respond_to?(:call) ? "min-w-0 text-sm text-slate-900" : LABEL_TEXT_CLASSES

      @template.content_tag(
        :label,
        class: "flex items-start gap-3 rounded-lg py-2 transition-colors " \
               "hover:bg-slate-50"
      ) do
        @template.check_box_tag(
          "#{object_name}[#{attribute}][]", value, checked,
          id: "#{object_name}_#{attribute}_#{value}",
          class: "mt-0.5 #{CHECKBOX_CLASSES}"
        ) +
          @template.content_tag(:span, text, class: text_class)
      end
    end

    # Renders select field with label and hint wrapper
    def render_select_with_wrapper(attribute, choices, options, html_options, &)
      label_text = options.delete(:label)
      hint = options.delete(:hint)
      wrapper_class = options.delete(:wrapper_class)

      # Separate standard select options from html options
      width = field_width(options)
      options.delete(:width)
      select_options = extract_select_options(options)
      remaining_html_options = html_options.merge(options)

      # A select is a text-like control as far as the proc is concerned, so it gets its message from there
      # too - see the note in field_wrapper. This is the second of the two places that appended one.
      @template.content_tag(:div, class: ["mb-6", wrapper_class].compact.join(" ").strip) do
        build_label(attribute, label_text, required: remaining_html_options[:required]) +
          build_hint(hint) +
          build_select_field(attribute, choices, select_options, remaining_html_options, width, &)
      end
    end

    # Build label element
    def build_label(attribute, label_text, required: false)
      return "".html_safe unless label_text

      decorated_label(attribute, label_text, required:)
    end

    # The label, and the asterisk that says the field is required.
    #
    # design.md asks for a visible required marker, and the hand-written forms carried one while the nine
    # forms built here did not - so on the admin half nothing distinguished a field you must fill from one
    # you may. `aria-hidden` on the mark: it is a visual convention, and the control's own `required`
    # attribute is what assistive tech reads.
    def decorated_label(attribute, label_text, required: false)
      label(attribute, class: LABEL_CLASSES) do
        @template.safe_join([label_text, required_indicator(required)])
      end
    end

    def required_indicator(required)
      return "".html_safe unless required

      @template.content_tag(:span, "*", class: "required-indicator", "aria-hidden": "true")
    end

    # Build hint element
    def build_hint(hint)
      return "".html_safe unless hint

      @template.content_tag(:p, hint, class: HINT_CLASSES)
    end

    # Build select field element
    def build_select_field(attribute, choices, select_options, html_options, width = nil, &)
      classes = [input_class(attribute), width].compact.join(" ")

      @template.content_tag(:div, class: "mt-2") do
        ActionView::Helpers::FormBuilder.instance_method(:select).bind(self).call(
          attribute, choices, select_options, html_options.merge(class: classes), &
        )
      end
    end

    # Extract standard select options from the options hash
    def extract_select_options(options)
      select_options = {}
      select_options[:include_blank] = options.delete(:include_blank) if options.key?(:include_blank)
      select_options[:prompt] = options.delete(:prompt) if options.key?(:prompt)
      select_options[:disabled] = options.delete(:disabled) if options.key?(:disabled)
      select_options[:selected] = options.delete(:selected) if options.key?(:selected)
      select_options
    end

    # Wraps a field with label, input, and error message
    def field_wrapper(attribute, options = {}, &)
      label_text = options.delete(:label) || attribute.to_s.humanize
      hint = options.delete(:hint)
      wrapper_class = options.delete(:wrapper_class) || ""
      required = options[:required]

      # No error message here. `config/initializers/field_error_proc.rb` renders one for every text-like
      # control and every select - which is all of them, since the checkbox builders below do not use this
      # wrapper - so appending a second put **two** messages under every invalid admin field: "Name can't be
      # blank" from the proc and "can't be blank" from here, in different colours, each with its own icon.
      #
      # The proc's version is the one to keep: it carries the attribute's name, so the field and the summary
      # say the same thing, and it is the same component the app half uses.
      @template.content_tag(:div, class: ["mb-6", wrapper_class].compact.join(" ").strip) do
        decorated_label(attribute, label_text, required:) +
          (hint ? @template.content_tag(:p, hint, class: HINT_CLASSES) : "".html_safe) +
          @template.content_tag(:div, class: "mt-2", &)
      end
    end

    # Returns the appropriate CSS class for an input based on validation state
    def input_class(attribute)
      if object&.errors && object.errors[attribute].any?
        INPUT_ERROR_CLASSES
      else
        INPUT_CLASSES
      end
    end

    # Merges input options with default classes, including the width class when one was named.
    def input_options(attribute, options = {})
      options[:class] = [input_class(attribute), field_width(options), options[:class]].compact.join(" ").strip
      options.delete(:width)
      options
    end

    # The control's width class, from `width:`. Unknown names raise rather than silently rendering full width.
    def field_width(options)
      name = options[:width] || :full

      FIELD_WIDTHS.fetch(name) do
        raise ArgumentError, "unknown field width #{name.inspect}, expected one of #{FIELD_WIDTHS.keys.inspect}"
      end
    end

    # Displays validation error for an attribute
    def badge(label, tone)
      @template.render("components/ui/badge", label: label, tone: tone)
    end

    # Formats a value for display in read-only fields
    def format_value(value)
      case value
      when TrueClass
        badge("Yes", :success)
      when FalseClass
        badge("No", :neutral)
      when Time, DateTime, Date
        value.strftime("%B %d, %Y")
      when nil
        # text-gray-400 measured 2.54:1, a straight AA failure, and the same one admin_helper.rb
        # had for absent values - which a test caught rather than an audit.
        @template.content_tag(:span, "—", class: "text-slate-600")
      else
        value.to_s
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
