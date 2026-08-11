# frozen_string_literal: true

module StocksHelper
  # The price and its movement, for a stock page's header.
  #
  # It is **derived** - the percentage comes from the two prices the form edits - so it cannot be a field
  # beside them without stating the same thing twice, once editable and once not. A record's page opens with
  # the figure you glance at, which is what Stripe does with a customer's balance.
  #
  # The direction is in the word as well as the colour, because green against red is not a distinction
  # everybody can make.
  def stock_price_summary(stock)
    return number_to_currency(stock.current_price) if stock.percentage_change.zero?

    direction = stock.percentage_change.positive? ? "up" : "down"

    "#{number_to_currency(stock.current_price)}, #{direction} #{stock.percentage_change_formatted} " \
      "on yesterday"
  end

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

    safe_join([opening, " ", held_by_scope_note(user)])
  end

  # The sentence that makes "4 of 25" mean something.
  #
  # **It carries no numbers.** The first version read "Held by counts owners across 1 classroom - 3
  # students with a portfolio", which is three ideas: what the column is, how wide the scope is, and how
  # the denominator was arrived at. The cell already states the figure, so this only has to say *whose*
  # figure it is - which also removes "1 classroom", a count that reads like a defect at one, and
  # "students with a portfolio", a phrase from the schema rather than from a staffroom.
  #
  # **And the column's name is set off from the prose.** Unmarked, "Held by shows how many..." is read as
  # a preposition and then re-read as a label - the reader stumbles once per visit. Microsoft's and
  # Google's style guides both say to bold the name of a UI element in running text, and this is the
  # first place in the app that names one.
  #
  # `tag.b`, not `<strong>`: the HTML spec reserves strong for *importance* - a screen reader stresses it
  # - while b is for "stylistically offset" text, which lists product names and keywords, and is exactly
  # a UI label. Assistive tech needs no help here anyway, since the label is a real `<th>` on the column.
  #
  # `font-medium text-slate-700` rather than bold: this is `text-sm text-slate-600` helper text, and a
  # full bold shouts. One step of weight and one of colour is enough to offset it. No colon after it -
  # the weight already marks the label, and a colon turns the clause into a glossary entry sitting at
  # the end of a sentence.
  def held_by_scope_note(user)
    rest = if user.admin?
             " shows how many students own each one, across every classroom."
           else
             " shows how many of your students own each one."
           end

    safe_join([tag.b("Held by", class: "font-medium text-slate-700"), rest])
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
