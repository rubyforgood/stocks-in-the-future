# frozen_string_literal: true

# `quarters.school_days` is gone, and the checkbox stays.
#
# It was added so perfect attendance could be derived from days attended rather than answered twice. The
# reasoning was wrong in two ways. The evidence was **seed data** - an entry flagged perfect with nil
# days, another treating 3 days as perfect - not a teacher's mistake. And the checkbox is not redundant
# with the day count: it is input the app cannot compute, from a teacher who may be taking the register
# in another system entirely.
#
# The cost told the same story. Deriving needed a denominator, which needed an admin form, which created
# a dependency from outside the grade book, which needed freezing at finalize, which left unfinalized
# books exposed, which needed an impact preview on the school-year form. Each piece existed to fix the
# previous piece's problem, and the default state of all of it was identical to the checkbox.
#
# What catches the one contradiction the app can actually see - a bonus claimed with no days recorded -
# is `GradeBookEarnings#unattended_bonus_entries`, which predates all of this and needs no new data.
class RemoveSchoolDaysFromQuarters < ActiveRecord::Migration[8.1]
  # `safety_assured`, deliberately. strong_migrations blocks a column drop because Active Record caches
  # attributes, so a running process from before the deploy still selects the column and breaks. That risk
  # is real and does not apply here: the column was added and removed on the same unreleased branch, the
  # migration that created it has never run anywhere but a developer's database, and nothing in the app
  # references it any more - `grep school_days app/` is empty.
  def change
    safety_assured do
      remove_column :quarters, :school_days, :integer,
                    comment: "Teaching days in the quarter. Perfect attendance is derived from it."
    end
  end
end
