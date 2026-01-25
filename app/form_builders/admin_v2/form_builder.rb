# frozen_string_literal: true

module AdminV2
  # rubocop:disable Metrics/ClassLength
  class FormBuilder < ActionView::Helpers::FormBuilder
    # Tailwind CSS classes for form elements
    INPUT_CLASSES = "block w-full rounded-md border-0 py-2 px-3 text-gray-900 ring-1 ring-inset ring-gray-300 " \
                    "placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 " \
                    "sm:text-sm sm:leading-6"

    INPUT_ERROR_CLASSES = "block w-full rounded-md border-0 py-2 px-3 text-red-900 ring-1 ring-inset " \
                          "ring-red-300 placeholder:text-red-300 focus:ring-2 focus:ring-inset " \
                          "focus:ring-red-500 sm:text-sm sm:leading-6"

    LABEL_CLASSES = "block text-sm font-medium leading-6 text-gray-900"

    ERROR_CLASSES = "mt-2 text-sm text-red-600"

    HINT_CLASSES = "mt-1 text-sm text-gray-500"

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

    # Currency field with proper formatting
    # Usage: f.currency_field :price_cents, multiplier: 0.01, decimals: 2
    def currency_field(attribute, options = {})
      multiplier = options.delete(:multiplier) || 0.01
      decimals = options.delete(:decimals) || 2

      field_wrapper(attribute, options) do
        value = object.public_send(attribute)
        display_value = value ? (value * multiplier).round(decimals) : nil

        number_field(attribute,
                     options.merge(
                       value: display_value,
                       step: (1.0 / (10**decimals)),
                       class: input_class(attribute),
                       data: { currency_multiplier: (1.0 / multiplier).to_i }
                     ))
      end
    end

    # Text area with proper styling
    def text_area(attribute, options = {})
      field_wrapper(attribute, options) do
        options[:rows] ||= 4
        options[:class] = "#{input_class(attribute)} #{options[:class] || ''}"
        super(attribute, options)
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
        select(attribute, collection,
               { include_blank: include_blank },
               input_options(attribute, options))
      end
    end

    # Boolean field (checkbox) with proper styling
    def boolean_field(attribute, options = {})
      hint = options.delete(:hint)
      label_text = options.delete(:label) || attribute.to_s.humanize

      @template.content_tag(:div, class: "relative flex items-start py-4") do
        @template.content_tag(:div, class: "flex h-6 items-center") do
          check_box(attribute,
                    class: "h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-600")
        end +
          @template.content_tag(:div, class: "ml-3 text-sm leading-6") do
            label(attribute, label_text, class: "font-medium text-gray-900") +
              (hint ? @template.content_tag(:p, hint, class: "text-gray-500") : "".html_safe)
          end
      end
    end

    # Collection checkboxes with proper styling
    def collection_check_boxes(attribute, collection, value_method, text_method, options = {})
      label_text = options.delete(:label) || attribute.to_s.humanize
      hint = options.delete(:hint)
      wrapper_class = options.delete(:wrapper_class) || ""

      @template.content_tag(:div, class: "mb-6 #{wrapper_class}") do
        build_checkbox_collection_label(label_text, hint) +
          build_checkbox_collection_items(attribute, collection, value_method, text_method) +
          error_message(attribute)
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
        select(attribute, choices,
               { include_blank: include_blank },
               input_options(attribute, options))
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
        @template.content_tag(:dt, label_text, class: "text-sm font-medium text-gray-500") +
          @template.content_tag(:dd, class: "mt-1 text-sm text-gray-900") do
            value.to_s.html_safe # rubocop:disable Rails/OutputSafety
          end +
          (hint ? @template.content_tag(:p, hint, class: HINT_CLASSES) : "".html_safe)
      end
    end

    # Submit button with Tailwind styling
    def submit_button(text = "Save", options = {})
      options[:class] = "inline-flex justify-center rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold " \
                        "text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 " \
                        "focus-visible:outline-offset-2 focus-visible:outline-blue-600 " \
                        "#{options[:class]}"

      submit(text, options)
    end

    # Cancel button (link styled as button)
    def cancel_button(text = "Cancel", url:, options: {})
      options[:class] = "inline-flex justify-center rounded-md bg-white px-4 py-2 text-sm font-semibold " \
                        "text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 " \
                        "#{options[:class]}"

      @template.link_to(text, url, options)
    end

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
    def build_checkbox_collection_label(label_text, hint)
      @template.content_tag(:label, label_text, class: LABEL_CLASSES) +
        (hint ? @template.content_tag(:p, hint, class: HINT_CLASSES) : "".html_safe)
    end

    # Build checkbox collection items
    def build_checkbox_collection_items(attribute, collection, value_method, text_method)
      @template.content_tag(:div, class: "mt-2 space-y-2") do
        collection.map do |item|
          build_single_checkbox(attribute, item, value_method, text_method)
        end.join.html_safe # rubocop:disable Rails/OutputSafety
      end
    end

    # Build a single checkbox item
    def build_single_checkbox(attribute, item, value_method, text_method)
      value = item.send(value_method)
      text = item.send(text_method)
      checkbox_id = "#{object_name}_#{attribute}_#{value}"
      checked = Array(object.send(attribute)).include?(value)

      @template.content_tag(:div, class: "relative flex items-start") do
        build_checkbox_input(attribute, value, checked, checkbox_id) +
          build_checkbox_label(checkbox_id, text)
      end
    end

    # Build checkbox input element
    def build_checkbox_input(attribute, value, checked, checkbox_id)
      @template.content_tag(:div, class: "flex h-6 items-center") do
        @template.check_box_tag(
          "#{object_name}[#{attribute}][]",
          value,
          checked,
          id: checkbox_id,
          class: "h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-600"
        )
      end
    end

    # Build checkbox label element
    def build_checkbox_label(checkbox_id, text)
      @template.content_tag(:div, class: "ml-3 text-sm leading-6") do
        @template.label_tag(checkbox_id, text, class: "font-medium text-gray-900")
      end
    end

    # Renders select field with label and hint wrapper
    def render_select_with_wrapper(attribute, choices, options, html_options, &)
      label_text = options.delete(:label)
      hint = options.delete(:hint)
      wrapper_class = options.delete(:wrapper_class)

      # Separate standard select options from html options
      select_options = extract_select_options(options)
      remaining_html_options = html_options.merge(options)

      @template.content_tag(:div, class: "mb-6 #{wrapper_class}") do
        build_label(attribute, label_text) +
          build_hint(hint) +
          build_select_field(attribute, choices, select_options, remaining_html_options, &) +
          error_message(attribute)
      end
    end

    # Build label element
    def build_label(attribute, label_text)
      return "".html_safe unless label_text

      label(attribute, label_text, class: LABEL_CLASSES)
    end

    # Build hint element
    def build_hint(hint)
      return "".html_safe unless hint

      @template.content_tag(:p, hint, class: HINT_CLASSES)
    end

    # Build select field element
    def build_select_field(attribute, choices, select_options, html_options, &)
      @template.content_tag(:div, class: "mt-2") do
        ActionView::Helpers::FormBuilder.instance_method(:select).bind(self).call(
          attribute, choices, select_options, html_options.merge(class: input_class(attribute)), &
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

      @template.content_tag(:div, class: "mb-6 #{wrapper_class}") do
        label(attribute, label_text, class: LABEL_CLASSES) +
          (hint ? @template.content_tag(:p, hint, class: HINT_CLASSES) : "".html_safe) +
          @template.content_tag(:div, class: "mt-2", &) +
          error_message(attribute)
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

    # Merges input options with default classes
    def input_options(attribute, options = {})
      options[:class] = "#{input_class(attribute)} #{options[:class] || ''}"
      options
    end

    # Displays validation error for an attribute
    def error_message(attribute)
      return "".html_safe unless object&.errors && object.errors[attribute].any?

      @template.content_tag(:p, class: ERROR_CLASSES, id: "#{attribute}-error") do
        @template.content_tag(:i, "", class: "fas fa-exclamation-circle mr-1") +
          object.errors[attribute].first
      end
    end

    # Formats a value for display in read-only fields
    def format_value(value)
      case value
      when TrueClass
        '<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ' \
        'bg-green-100 text-green-800">Yes</span>'
      when FalseClass
        '<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ' \
        'bg-gray-100 text-gray-800">No</span>'
      when Time, DateTime, Date
        value.strftime("%B %d, %Y")
      when nil
        '<span class="text-gray-400">—</span>'
      else
        value.to_s
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
