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
  # The mirror of the above, for the admin teacher form's classroom picker: the classroom's name over the
  # school it belongs to.
  #
  # The school is on the row because the picker no longer has a school filter above it. Two schools can each
  # run a "Grade 5", so a bare name is ambiguous - and a teacher may hold classrooms in more than one, which
  # this shows rather than asserting in a sentence.
  def classroom_option_label
    lambda do |classroom|
      safe_join(
        [
          tag.span(classroom.name, class: "block truncate font-medium"),
          tag.span(classroom.school_name, class: "block truncate text-xs text-slate-600")
        ]
      )
    end
  end

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
