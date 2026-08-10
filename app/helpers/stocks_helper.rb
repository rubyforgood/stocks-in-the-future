# frozen_string_literal: true

module StocksHelper
  # What the trading floor's list of buyable companies is, said in the reader's own terms.
  #
  # The single string this replaced was "Companies you can buy shares in right now", which is written in
  # a student's voice and was shown to teachers and admins too - neither of whom can buy anything. A
  # description that addresses the wrong person is worse than none, because it tells them the page is for
  # them and then does not behave that way.
  #
  # Staff also get the Held by column explained here, because "4 of 25" is unreadable without knowing
  # which twenty-five, and the twenty-five differ by role. The section's description is where design.md
  # puts an explanation of the section: under the heading, above the table.
  def active_stocks_description(user, students: nil)
    return "Companies you can buy shares in right now." unless user.teacher? || user.admin?

    opening = "Companies your students can buy shares in right now."
    return opening unless students.to_i.positive?

    "#{opening} #{held_by_scope_note(user)}"
  end

  # The sentence that makes "4 of 25" mean something.
  #
  # **It carries no numbers.** The first version read "Held by counts owners across 1 classroom - 3
  # students with a portfolio", which is three ideas: what the column is, how wide the scope is, and how
  # the denominator was arrived at. The cell already states the figure, so this only has to say *whose*
  # figure it is - which also removes "1 classroom", a count that reads like a defect at one, and
  # "students with a portfolio", a phrase from the schema rather than from a staffroom.
  def held_by_scope_note(user)
    if user.admin?
      "Held by shows how many students own each one, across every classroom."
    else
      "Held by shows how many of your students own each one."
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
