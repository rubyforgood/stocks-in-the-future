# frozen_string_literal: true

class EarningsSummary
  def initialize(portfolio)
    @portfolio = portfolio
  end

  def fees_by_reason
    earnings_by_reason = PortfolioTransaction
                         .where(portfolio: @portfolio, transaction_type: :fee)
                         .group("reason")
                         .sum(:amount_cents)

    return [] if earnings_by_reason.blank?

    earnings_by_reason.map do |reason, sum_value|
      {
        reason: reason,
        reason_humanized: PortfolioTransaction::REASONS.fetch(reason.to_sym) { reason.to_s.humanize },
        total_cents: sum_value,
        total: (sum_value.to_f / 100).round(2)
      }
    end
  end
end
