# frozen_string_literal: true

# Every invalid field shows a rose border **and** a visible message, so the error is never carried by
# colour alone (WCAG 1.4.1). design.md specifies this as automatic app-wide rather than per call site,
# which is the only way the hand-written forms get it: `Admin::FormBuilder` and `Shadcn::FormBuilder`
# already swap `tw-input-primary` for `tw-input-error` themselves, but `classrooms/_form`,
# `students/new` and `students/edit` write their inputs by hand and had no error treatment at all.
#
# Rails calls this for the **label** as well as the field, and for hidden, checkbox and radio inputs.
# Only a text-like control is touched: a message under a hidden field would appear from nowhere, and a
# checkbox group's message belongs on its fieldset, which `FormErrorsHelper#field_error` places by hand.
#
# A control that already carries `aria-describedby` is left alone, so a hand-placed message never
# doubles with a generated one.
ActiveSupport.on_load(:action_view) do
  ActionView::Base.field_error_proc = proc do |html_tag, instance|
    fragment = Nokogiri::HTML5.fragment(html_tag)
    node = fragment.element_children.first

    # Rails' own behaviour is to wrap the field in `<div class="field_with_errors">`, and replacing the
    # proc replaces that too. It is kept: the class is a marker the suite already selects on - a test
    # asserting `.field_with_errors` containing "Username" is matching the wrapped *label* - and dropping
    # it turned that test red for a reason that had nothing to do with what it was testing.
    wrap = ->(content) { ActionController::Base.helpers.tag.div(content, class: "field_with_errors") }

    skip = node.nil? ||
           node.name == "label" ||
           node["aria-describedby"].present? ||
           (node.name == "input" && node["type"].in?(%w[hidden checkbox radio submit]))

    if skip
      wrap.call(html_tag.html_safe) # rubocop:disable Rails/OutputSafety
    else
      # The full message, so the field and the summary say the same thing rather than two versions of
      # it. Sentence case and no trailing period, per design.md's message-copy rule.
      attribute = instance.instance_variable_get(:@method_name)
      label = instance.object.class.human_attribute_name(attribute)
      text = Array(instance.error_message).map { |m| "#{label} #{m}" }.join(", ").delete_suffix(".")

      id = node["id"].presence
      message_id = id ? "#{id}_error" : nil

      node["aria-invalid"] = "true"
      node["aria-describedby"] = message_id if message_id
      # The error variant of the input token, in place of the resting one rather than alongside it -
      # both set a border colour and the later declaration would win by file order, not by intent.
      node["class"] = node["class"].to_s.sub("tw-input-primary", "tw-input-error")
      node["class"] = "#{node['class']} tw-input-error".strip unless node["class"].include?("tw-input-error")

      message = Nokogiri::HTML5.fragment(
        ActionController::Base.helpers.tag.p(
          text,
          id: message_id,
          class: "mt-1 flex items-start gap-1.5 text-sm text-slate-700"
        )
      )

      wrap.call((fragment.to_html + message.to_html).html_safe) # rubocop:disable Rails/OutputSafety
    end
  end
end
