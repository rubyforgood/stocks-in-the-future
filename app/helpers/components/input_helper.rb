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
      " border-0 focus-visible:outline-none focus-visible:shadow-none focus-visible:ring-transparent"
    end

    def border_variant_default_styling
      "shadow-sm focus-visible:outline-none focus-visible:ring-2a " \
        "focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:border-muted"
    end
  end
end
