# frozen_string_literal: true

module ClassroomsHelper
  # The label for one teacher in the classroom form's picker: a name over an email.
  #
  # A callable rather than a symbol, which `Ui::FormBuilder#collection_check_boxes` accepts, so the group
  # is built by the builder like every other group instead of being written out by hand - which is how it
  # came to be the one group in the app with its own fieldset markup.
  #
  # The email is not decoration. Two teachers whose names begin with T were previously told apart by a
  # 32px avatar disc containing one letter, which is to say not at all.
  def teacher_option_label
    lambda do |teacher|
      safe_join(
        [
          tag.span(teacher.display_name, class: "block truncate font-medium"),
          tag.span(teacher.email, class: "block truncate text-xs text-slate-600")
        ]
      )
    end
  end
end
