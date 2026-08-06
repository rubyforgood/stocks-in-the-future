# frozen_string_literal: true

# What a grade book will pay, per entry and in total, before it is finalized.
#
# It runs `EarningsCalculator` - the same class `DistributeEarnings` pays from - so the figures on
# screen are the payout by construction rather than by agreement. That calculator was extracted for
# exactly this ("so the same figures can be shown to a student before a grade book is finalised,
# without a second implementation drifting away from the one that actually pays out") and nothing had
# ever used it that way: a teacher clicked Finalize, which is irreversible and deposits real money into
# every student's portfolio, with no statement of what it would pay.
#
# The previous quarter's entries are fetched once, from GradeBook, rather than per row - improvement
# earnings need them, and a lookup per entry would be a query per student.
class GradeBookEarnings
  def initialize(grade_book)
    @grade_book = grade_book
    @previous = grade_book.previous_entries_by_user_id
    @cache = {}
  end

  # Memoised on the entry's id, because a row asks for its own figure and the totals ask for all of
  # them; without this every entry is calculated twice.
  def for(entry)
    @cache[entry.id] ||= EarningsCalculator.execute(entry, @previous[entry.user_id])
  end

  def total_cents
    entries.sum { |entry| self.for(entry).total }
  end

  # Keyed the way the money is actually written: DistributeEarnings creates one transaction per reason,
  # so these three subtotals are what appears on the students' statements.
  def totals_by_reason
    entries.each_with_object({ attendance: 0, math: 0, reading: 0 }) do |entry, sums|
      earnings = self.for(entry)
      sums[:attendance] += earnings.attendance
      sums[:math] += earnings.math
      sums[:reading] += earnings.reading
    end
  end

  def student_count
    entries.size
  end

  # An entry claiming the perfect-attendance bonus while recording no days is incoherent whatever the
  # quarter's length, so it can be flagged without knowing how many school days there were - which is
  # the number this app does not store. It is not hypothetical: the development seeds contain one, paid
  # a bonus with no attendance at all.
  def unattended_bonus_entries
    entries.select { |entry| entry.is_perfect_attendance && entry.attendance_days.to_i.zero? }
  end

  def unattended_bonus?
    unattended_bonus_entries.any?
  end

  private

  def entries
    @entries ||= @grade_book.grade_entries.to_a
  end
end
