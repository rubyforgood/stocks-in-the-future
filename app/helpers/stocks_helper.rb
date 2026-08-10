# frozen_string_literal: true

module StocksHelper
  # What the trading floor's list of buyable companies is, said in the reader's own terms.
  #
  # The single string this replaced was "Companies you can buy shares in right now", which is written in
  # a student's voice and was shown to teachers and admins too - neither of whom can buy anything. A
  # description that addresses the wrong person is worse than none, because it tells them the page is for
  # them and then does not behave that way.
  #
  # Staff also get the scope of the Held by column stated here rather than in a tooltip or a legend: a
  # figure like "2 of 3" is unreadable without knowing which three, and the denominator is different for
  # an admin (every classroom) and a teacher (their own). The section's description is where design.md
  # puts an explanation of the section, under the heading and above the table.
  def active_stocks_description(user, investors: nil, classrooms: nil)
    return "Companies you can buy shares in right now." unless user.teacher? || user.admin?

    opening = "Companies your students can buy shares in right now."
    return opening unless investors.to_i.positive?

    "#{opening} #{held_by_scope_note(user, investors:, classrooms:)}"
  end

  # The sentence that makes "2 of 3" mean something.
  #
  # Derived from the counts rather than written out per role, so it cannot claim a scope the query does
  # not use - the same reasoning as interpolating a retention window from its constant. An admin's
  # classroom count is stated because "every classroom" is otherwise an unbounded claim; a teacher's is
  # not, because "your classrooms" is already exact for them.
  def held_by_scope_note(user, investors:, classrooms: nil)
    people = "#{pluralize(investors, 'student')} with a portfolio"

    if user.admin?
      "Held by counts owners across #{pluralize(classrooms.to_i, 'classroom')} - #{people}."
    else
      "Held by counts owners in your classrooms - #{people}."
    end
  end

  # A stock's identity line: the ticker, and the market it trades on.
  #
  # The trading floor's header has said "Company (exchange)" since it was written and the cell has never
  # contained an exchange - `stock_exchange` is populated on every active stock and was rendered only on
  # stocks#show. A ticker without its market is ambiguous, which is why Bloomberg, Yahoo Finance and
  # Google Finance all render the pair.
  #
  # Nil-safe on purpose: archived stocks carry none of the company fields, and this sits in a cell rather
  # than a column so an absent value costs nothing. The same is not true of a column - see _stocks_table.
  def stock_market_note(stock)
    stock.stock_exchange.presence
  end
end
