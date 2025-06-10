# frozen_string_literal: true

module Components
  module FormsHelper
    def render_form_with(**opts, &block)
      form_with(**opts.merge(builder: Shadcn::FormBuilder), &block)
    end

    def render_form_for(obj, **opts, &block)
      form_for(obj, **opts.merge(builder: Shadcn::FormBuilder), html: opts, &block)
    end
  end
end
