# frozen_string_literal: true

module Components
  module FormsHelper
    def render_form_with(**, &)
      form_with(**, builder: Shadcn::FormBuilder, &)
    end

    def render_form_for(obj, **opts, &)
      form_for(obj, **opts, builder: Shadcn::FormBuilder, html: opts, &)
    end
  end
end
