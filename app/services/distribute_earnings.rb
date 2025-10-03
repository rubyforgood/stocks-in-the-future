# frozen_string_literal: true

class DistributeEarnings
  def initialize(grade_book)
    @grade_book = grade_book
    @previous_entries = find_previous_entries
  end

  def self.execute(...)
    new(...).execute
  end

  def execute
    return unless @grade_book.verified?

    ActiveRecord::Base.transaction do
      distribute_funds_to_students
      @grade_book.completed!
    end
  end

  private

  def distribute_funds_to_students
    @grade_book.grade_entries.each do |entry|
      earnings = entry.total_earnings + calculate_improvement_bonus(entry)
      next if earnings.zero?

      create_earnings_transaction(entry.user, earnings)
    end
  end

  def find_previous_entries
    previous_quarter = @grade_book.quarter.previous
    return {} unless previous_quarter

    previous_grade_book = GradeBook.find_by(classroom: @grade_book.classroom, quarter: previous_quarter)
    return {} unless previous_grade_book

    previous_grade_book.grade_entries.to_a.group_by(&:user_id)
  end

  def calculate_improvement_bonus(current_entry)
    previous_entry = @previous_entries[current_entry.user_id]&.first
    return 0 unless previous_entry

    current_entry.improvement_earnings(previous_entry)
  end

  def create_earnings_transaction(user, amount_cents)
    user.portfolio.portfolio_transactions.create!(
      amount_cents: amount_cents,
      transaction_type: :deposit,
      reason: PortfolioTransaction::REASONS[:grade_earnings] # TODO: Replace this with the broken out reasons
    )
  end
end
