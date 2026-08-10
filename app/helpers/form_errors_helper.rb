# frozen_string_literal: true

# The hand-placed half of design.md's field-level validation pattern.
#
# `config/initializers/field_error_proc.rb` handles every text-like control automatically. It cannot
# handle a **group**: a checkbox group's error belongs to the fieldset, not to whichever box Rails
# happened to render first, and Rails calls the proc once per field. So a group calls these two.
module FormErrorsHelper
  # `aria-invalid` and `aria-describedby`, splatted onto a `<fieldset>` via `tag.attributes`, so
  # assistive tech ties the group to its message. Returns nothing when the attribute is valid, which is
  # what keeps the attributes off a clean field rather than setting `aria-invalid="false"` everywhere.
  def field_error_attrs(record, attribute)
    return {} if record.errors[attribute].blank?

    { "aria-invalid" => "true", "aria-describedby" => field_error_id(record, attribute) }
  end

  # The message, under the group, with the id `field_error_attrs` points at.
  def field_error(record, attribute)
    messages = record.errors.full_messages_for(attribute)
    return if messages.empty?

    field_error_message(
      messages.join(", ").delete_suffix("."),
      id: field_error_id(record, attribute),
      margin: "mt-2"
    )
  end

  # **One definition of what a field-level validation message looks like**, called from here for a group and
  # from `config/initializers/field_error_proc.rb` for every text-like control. Two definitions of one thing
  # is how the field and the group would come to disagree.
  #
  # **The icon is the point.** Without it the message is grey text under a field, which is what helper text
  # looks like - reported as exactly that. design.md's Validation section calls for a leading icon on a
  # field-level message, and it is also what stops the error being carried by the input's border colour alone
  # (WCAG 1.4.1): the border, the icon and the words are three channels, and only the last two survive a
  # reader who cannot see the first.
  #
  # **red, not rose.** The inherited text in design.md says rose, which is this app's *destructive-action*
  # family - `.tw-btn-danger`, the confirm dialog's accept. Validation here is red: `.tw-input-error` is
  # `border-red-600` with a `focus:outline-red-700`, and `shared/_form_errors` is red-50 / red-200 / red-700.
  # Using rose would put a second error hue in the product. red-600 matches the invalid field's own border,
  # and measured on white it is 4.77:1 - past AA for text and well past 1.4.11's 3:1 for a non-text mark.
  #
  # `aria-hidden` comes from `lucide_icon` by default, which is right: the words carry the meaning and the
  # message is already tied to the control by `aria-describedby`.
  def field_error_message(text, id: nil, margin: "mt-1")
    tag.p id: id, class: "#{margin} flex items-start gap-1.5 text-sm text-slate-700" do
      safe_join([lucide_icon("circle-alert", class: "mt-0.5 size-4 shrink-0 text-red-600"), tag.span(text)])
    end
  end

  private

  def field_error_id(record, attribute)
    "#{record.model_name.param_key}_#{attribute}_error"
  end
end
