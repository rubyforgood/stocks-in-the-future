# frozen_string_literal: true

module Components
  module ButtonHelper
    def render_button(label = "", text: nil, variant: :default, as: :button, href: nil, data: {}, **options, &block)
      base_classes = base_class_styling
      variant_classes = case variant.to_sym
                        when :default
                          " bg-primary text-primary-foreground hover:bg-primary/90 "
                        when :secondary
                          " bg-secondary text-secondary-foreground hover:bg-secondary/80 "
                        when :error, :danger, :alert, :destructive
                          " bg-destructive text-destructive-foreground hover:bg-destructive/90 "
                        when :outline
                          "  border border-input bg-background hover:bg-accent hover:text-accent-foreground"
                        when :ghost
                          " hover:bg-accent hover:text-accent-foreground  "
                        end
      button_classes = "#{base_classes} #{variant_classes} #{options[:class]}"
      button_classes = tw(button_classes)
      text = label if label.present?
      text = capture(&block) if block
      render "components/ui/button", text:, button_classes:, as:, href:, data:, **options
    end

    private

    def base_class_styling
      # Focus ring needs an explicit colour. Tailwind v4 falls back to
      # currentColor, which on a primary button (white label) produced a white
      # ring over a white ring-offset on a white page - an invisible focus
      # indicator. ring-2 and ring-3 were also both set, which conflicts.
      " inline-flex items-center justify-center rounded-md text-sm font-medium " \
        "ring-offset-background transition-colors focus-visible:outline-hidden " \
        "focus-visible:ring-2 focus-visible:ring-sitf-primary focus-visible:ring-offset-2 " \
        "disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 "
    end
  end
end
