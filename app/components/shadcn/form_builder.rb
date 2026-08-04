# frozen_string_literal: true

module Shadcn
  class FormBuilder < ActionView::Helpers::FormBuilder
    def label(method, options = {})
      error_class = @object.errors[method].any? ? "error" : ""
      options[:class] = @template.tw("#{options[:class]} #{error_class}")
      @template.render_label(name: "#{object_name}[#{method}]", label: label_for(@object, method), **options)
    end

    def text_field(method, options = {})
      error_class = @object.errors[method].any? ? "error" : ""
      options[:class] = @template.tw("#{options[:class]} #{error_class}")
      @template.render_input(
        name: "#{object_name}[#{method}]",
        id: "#{object_name}_#{method}",
        value: @object.send(method),
        type: "text", **options
      )
    end

    def password_field(method, options = {})
      error_class = @object.errors[method].any? ? "error" : ""
      options[:class] = @template.tw("#{options[:class]} #{error_class}")
      @template.render_input(
        name: "#{object_name}[#{method}]",
        id: "#{object_name}_#{method}",
        value: @object.send(method),
        type: "password", **options
      )
    end

    def email_field(method, options = {})
      error_class = @object.errors[method].any? ? "error" : ""
      options[:class] = @template.tw("#{options[:class]} #{error_class}")
      @template.render_input(
        name: "#{object_name}[#{method}]",
        id: "#{object_name}_#{method}",
        value: @object.send(method),
        type: "email", **options
      )
    end

    # Renders the app's own primary button rather than delegating to render_button, whose shadcn
    # --primary is a near-black navy. Any form using render_form_for got that navy for its submit,
    # which is why the sign-up button was the one off-brand primary in the product.
    def submit(value = nil, options = {})
      options[:class] = "tw-btn-primary #{options[:class]}".strip

      super
    end

    private

    def label_for(object, method)
      return method.capitalize if object.nil?

      object.class.human_attribute_name(method)
    end
  end
end
