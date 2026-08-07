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

  # The message, under the group. Same shape as the one the proc generates - the full message, so the
  # field and the summary read the same - with the id `field_error_attrs` points at.
  def field_error(record, attribute)
    messages = record.errors.full_messages_for(attribute)
    return if messages.empty?

    tag.p messages.join(", ").delete_suffix("."),
          id: field_error_id(record, attribute),
          class: "mt-2 text-sm text-slate-700"
  end

  private

  def field_error_id(record, attribute)
    "#{record.model_name.param_key}_#{attribute}_error"
  end
end
