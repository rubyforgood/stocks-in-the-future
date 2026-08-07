# frozen_string_literal: true

module Shadcn
  class FormBuilder < ActionView::Helpers::FormBuilder
    # These render plain Rails fields on the app's own named classes rather than delegating to
    # render_input, whose shadcn base (h-10, rounded-md, border-input, a ring focus) is a different
    # control from tw-input-primary (min-h-11, rounded-lg, border-slate-300, an outline focus).
    #
    # Passing tw-input-primary *through* render_input did not work and looked like it did: the field
    # ended up carrying both strings, and since utilities beat component classes the shadcn ones won.
    # So the sign-in and sign-up pages - the two every user sees first - kept a 40px rounded-md field
    # while every other form in the app moved to 44px rounded-lg. Same trap as this builder's submit,
    # which used to hand off to render_button and quietly reintroduced the shadcn navy.
    def label(method, options = {})
      options[:class] = "tw-label-primary #{options[:class]}".strip
      super(method, label_for(@object, method), options)
    end

    def text_field(method, options = {})
      options[:class] = field_class(method, options[:class])
      super
    end

    def password_field(method, options = {})
      options[:class] = field_class(method, options[:class])
      super
    end

    def email_field(method, options = {})
      options[:class] = field_class(method, options[:class])
      super
    end

    def submit(value = nil, options = {})
      options[:class] = "tw-btn-primary #{options[:class]}".strip

      super
    end

    private

    # tw-input-error puts the red on the border and the focus outline, never on the value the user
    # typed.
    def field_class(method, extra)
      errors = @object ? @object.errors[method] : []
      base = errors.any? ? "tw-input-error" : "tw-input-primary"

      "#{base} #{extra}".strip
    end

    def label_for(object, method)
      return method.capitalize if object.nil?

      object.class.human_attribute_name(method)
    end
  end
end
