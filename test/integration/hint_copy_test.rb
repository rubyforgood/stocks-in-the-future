# frozen_string_literal: true

require "test_helper"

# A hint says something the label cannot.
#
# Reported as "none of this helper text makes sense", and the count was the answer: **twenty-six of the
# app's hints restated their own label.** "Full company name" under a field labelled Company name, "Industry
# sector" under Industry, "Select the school for this school year" under School, "Re-enter password to
# confirm" under Password confirmation. GOV.UK, Polaris, Carbon and Material 3 all name this as the thing
# hint text must not do, and the cost is not just the wasted line: a reader who finds the first three hints
# empty stops reading the fourth, which is the one saying a background job overwrites the field.
#
# So this fails on the shape rather than on a list of strings, because the list would be out of date the
# first time somebody adds a field.
class HintCopyTest < ActionDispatch::IntegrationTest
  # Words that carry no meaning for the comparison. "Enter the school name" against a label of "School name"
  # is a restatement, and only these words differ.
  FILLER = %w[a an and are as at be by for from in is it its of on or that the this to with your].freeze

  # A control's own verb. "Enter", "Select" and "Choose" describe what the widget already announces - a text
  # box is for typing in and a select is for selecting from. GOV.UK's hint guidance is explicit that hint
  # text is for what the *answer* should be, not for how to operate the field.
  #
  # **A choice group is the exception, and GOV.UK is the reason.** Its own checkbox pattern ships
  # "Select all that apply" as the hint, because with a group the thing a reader cannot see is *how many*
  # they may pick - one, or as many as apply. So the imperative is the content there rather than filler,
  # and "Select all classrooms this teacher teaches" is the correct hint for a `<fieldset>` of checkboxes
  # and would be wrong on a text field.
  #
  # The first version of this test banned the verb everywhere, which would have failed that copy. It did
  # not fail, and only because group labels are `<legend>` and the selector then read `label` - so the
  # rule was over-broad *and* untested on the fields it was wrong about. Both are fixed: groups are
  # checked for restatement and exempt from the verb.
  IMPERATIVES = /\A(enter|select|choose|type|write|input|pick|fill|specify|provide)\b/i

  def words(text)
    text.to_s.downcase.gsub(/[^a-z0-9\s]/, " ").split - FILLER
  end

  # Every field on a page, as [label, hint]. The builder renders the hint as a sibling of the label inside
  # the field wrapper, so they are paired through the wrapper rather than by document order - two fields
  # where only the second has a hint would otherwise pair the first label with the second hint.
  def fields_on(path)
    get path

    assert_response :success

    # `<legend>` as well as `<label>`: a checkbox group names itself with a legend, which is the only
    # element that can name a group - so a selector of `label` alone silently skips every group on the page.
    response.parsed_body.css("label.tw-label-primary, legend.tw-label-primary").filter_map do |name|
      hint = name.parent&.at_css("p.tw-field-hint")
      next unless hint

      [name.text.strip.delete_suffix("*").strip, hint.text.strip, name.name == "legend"]
    end
  end

  # **A field hint is a sentence, so it ends like one.** Twelve of sixty did not, which is what a reader
  # noticed - "some have periods at the end and others don't".
  #
  # Nine of those twelve were not field hints at all: `_stat`'s caption takes a local also called `hint`, and
  # a caption under a figure - "Ready to spend on shares", "All deposits, all time" - is a fragment, which is
  # what Stripe and Polaris put under a metric. They render `p.mt-1.text-xs.text-slate-500`, not
  # `p.tw-field-hint`, so this rule reads the class and leaves them alone. Two components, one local name.
  def assert_hint_is_a_sentence(path, label, hint)
    assert_match(
      /[.?!]\z/, hint,
      "#{path}: \"#{label}\" is hinted \"#{hint}\" with no full stop. A field hint is a " \
      "sentence; a fragment under a figure is `_stat`'s caption, which is a different component."
    )
  end

  def assert_hint_earns_its_place(path, label, hint, group)
    assert_hint_is_a_sentence(path, label, hint)

    unless group
      assert_no_match IMPERATIVES, hint,
                      "#{path}: \"#{label}\" is hinted \"#{hint}\" - a control's own verb is not a hint"
    end

    label_words = words(label)
    hint_words = words(hint)
    return if label_words.empty?

    restates = (label_words - hint_words).empty? && hint_words.size <= label_words.size + 3

    assert_not restates,
               "#{path}: \"#{label}\" is hinted \"#{hint}\", which is the label again. Say what the label " \
               "cannot - a format, a consequence, or who sees the value - or drop the hint."
  end

  test "no admin hint restates its own label" do
    classroom = create(:classroom)
    create(:student, classroom:)
    create(:stock)
    create(:school)
    sign_in(create(:admin, admin: true, classroom: nil))

    paths = [new_admin_teacher_path, new_admin_student_path, new_admin_school_path, new_admin_stock_path,
             new_admin_classroom_path, new_admin_school_year_path, new_admin_announcement_path,
             new_admin_user_path, new_admin_portfolio_transaction_path]

    assert_operator sweep(paths), :>, 5, "the selectors have probably drifted"
  end

  # **And the app side, which this test did not look at.** It walked nine admin create pages and stopped
  # there, so the forms a teacher and a student actually use - the classroom form, the student forms, the
  # profile - were never checked by the rule they are subject to. A copy audit scoped to one half of a
  # product is how the two halves come to read differently, which is the thing design.md's "both sides"
  # instruction exists to stop.
  test "no app-side hint restates its own label" do
    classroom = create(:classroom, :with_trading)
    create(:teacher_classroom, teacher: create(:teacher), classroom:)
    create(:student, classroom:)
    # Signed in as an admin because `ClassroomPolicy#new?` is admin-only, and the point here is to render
    # the forms rather than to test who reaches them.
    sign_in(create(:admin, admin: true, classroom: nil))

    assert_operator sweep(
      [new_classroom_path, edit_classroom_path(classroom),
       new_classroom_student_path(classroom), edit_profile_path]
    ),
                    :>, 5, "the selectors have probably drifted"
  end

  private

  def sweep(paths)
    checked = 0

    paths.each do |path|
      fields_on(path).each do |label, hint, group|
        checked += 1
        assert_hint_earns_its_place(path, label, hint, group)
      end
    end

    # Zero fields would pass every assertion, which is how a copy test quietly stops testing copy.
    checked
  end
end
