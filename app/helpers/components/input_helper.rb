# frozen_string_literal: true

module Components
  module InputHelper
    def render_input(name:, label: false, id: nil, type: :text, value: nil, **options)
      options[:class] = border_styling(options[:class])

      options[:class] << case options[:variant]
                         when :borderless
                           borderless_variant_styling
                         else
                           border_variant_default_styling
                         end
      options[:class] = tw(options[:class])

      options.reverse_merge!(
        label: options[:lable] || false,
        required: options[:required] || false,
        disabled: options[:disabled] || false,
        readonly: options[:readonly] || false,
        placeholder: options[:placeholder] || "",
        autocomplete: options[:autocomplete] || "",
        autocapitalize: options[:autocapitalize] || nil,
        autocorrect: options[:autocorrect] || nil
      )
      render partial: "components/ui/input", locals: {
        type:,
        label:,
        name:,
        value:,
        id:,
        options: options
      }
    end

    private

    def border_styling(options_class)
      "flex h-10 w-full rounded-md border border-input bg-background px-3 " \
        "py-2 text-sm transition-colors ring-offset-background file:border-0 " \
        "file:bg-transparent file:text-sm file:font-medium " \
        "placeholder:text-muted-foreground disabled:cursor-not-allowed " \
        "disabled:opacity-50 #{options_class} "
    end

    def borderless_variant_styling
      " border-0 focus-visible:outline-hidden focus-visible:shadow-none focus-visible:ring-transparent"
    end

    # Focus ring: explicit brand colour at 2px with an offset.
    # `ring-2a` was an invalid class that compiled to nothing, and no ring
    # colour was set, so the indicator fell back to currentColor by accident
    # while `border-muted` lightened the boundary on focus. sitf-primary on
    # white measures 5.9:1, clearing the 3:1 required by WCAG 1.4.11.
    def border_variant_default_styling
      "shadow-xs focus-visible:outline-hidden focus-visible:ring-2 " \
        "focus-visible:ring-sitf-primary focus-visible:ring-offset-2 " \
        "focus-visible:border-sitf-primary"
    end
  end
end
