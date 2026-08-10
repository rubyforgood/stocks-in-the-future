# frozen_string_literal: true

# A record that belongs to a SchoolYear but is asked for a **School** and a **Year**.
#
# No form in this app asks for a SchoolYear: both halves offer two selects and the pair is
# found-or-created. Before this, that left every validation failure naming a field nobody could see -
# "School year must exist", with neither select marked - so the reader was told about something that is
# not on the page.
#
# The model accepts what the forms post instead. `school_id` and `year_id` are virtual; they fall back
# to the association when they were not assigned, which is every other way a record gets made - a seed, a
# factory, a console - so nothing else has to change.
#
# Two details worth keeping:
#
# - **`optional: true` on the association.** The `NOT NULL` column and the validation below keep it
#   required in fact. Leaving Rails' own presence check on would add a second error for one omission,
#   which is the duplicate this model already carried once, by hand.
# - **`find_or_initialize_by` with `autosave`.** The SchoolYear is written only if the owning record
#   saves. Resolving it eagerly - which is what the controllers used to do, before save - left an orphan
#   row behind every failed submit.
module SchoolYearFields
  extend ActiveSupport::Concern

  included do
    belongs_to :school_year, optional: true, autosave: true

    attr_writer :school_id, :year_id

    before_validation :resolve_school_year
    validate :school_and_year_chosen
  end

  # Falls back to the association, so an edit form repopulates its selects without a view digging
  # through `school_year.school.id` - but **only when nothing was assigned**. A form that sends an empty
  # select is clearing the field, and falling back there would silently keep the old value and report a
  # save that did nothing.
  def school_id
    return @school_id.presence unless @school_id.nil?

    school_year&.school_id
  end

  def year_id
    return @year_id.presence unless @year_id.nil?

    school_year&.year_id
  end

  private

  def resolve_school_year
    return if school_id.blank? || year_id.blank?
    return if school_year && school_year.school_id.to_s == school_id.to_s &&
              school_year.year_id.to_s == year_id.to_s

    self.school_year = SchoolYear.find_or_initialize_by(school_id:, year_id:)
  end

  # On the two fields the forms have, not on the association they combine into.
  #
  # An association assigned directly satisfies it, which is every path that is not a form: a seed, a
  # factory, `create(:classroom)`. Those hand a SchoolYear over whole - and it may be unsaved, in which
  # case its own school_id is still nil, so checking the ids rather than the association would fail a
  # perfectly valid `build`.
  def school_and_year_chosen
    return if school_year.present? && @school_id.nil? && @year_id.nil?

    errors.add(:school_id, :blank) if school_id.blank?
    errors.add(:year_id, :blank) if year_id.blank?
  end
end
