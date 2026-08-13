# frozen_string_literal: true

# Works out what one grade entry earns, in cents. Pure: it reads the entry and the
# same student's entry from the previous quarter and returns amounts. It writes
# nothing - DistributeEarnings persists what this returns.
#
# Extracted from DistributeEarnings so the same figures can be shown to a student
# before a grade book is finalized, without a second implementation drifting away from
# the one that actually pays out.
class EarningsCalculator
  Earnings = Struct.new(:attendance, :math, :reading) do
    def total
      attendance + math + reading
    end

    # Keyed by PortfolioTransaction reason, because that is what these amounts become.
    # Order matters only in that it fixes the order the transactions are written in.
    def by_reason
      { attendance_earnings: attendance, math_earnings: math, reading_earnings: reading }
    end
  end

  # previous_entry is nil in the first quarter, and also when the student has no entry
  # in the previous quarter's grade book. Both mean "no improvement to pay".
  def initialize(entry, previous_entry = nil)
    @entry = entry
    @previous_entry = previous_entry
  end

  def self.execute(...)
    new(...).execute
  end

  def execute
    Earnings.new(attendance, math, reading)
  end

  private

  attr_reader :entry, :previous_entry

  def attendance
    entry.earnings_for_attendance + entry.attendance_perfect_earnings
  end

  def math
    entry.earnings_for_math + entry.math_improvement_earnings(previous_entry)
  end

  def reading
    entry.earnings_for_reading + entry.reading_improvement_earnings(previous_entry)
  end
end
