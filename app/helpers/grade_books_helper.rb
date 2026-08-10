# frozen_string_literal: true

# The one place a grade book's state is turned into words.
module GradeBooksHelper
  # `status` is an enum with three values and none of them was safe to print raw.
  #
  # **"Draft" was reported as unreadable**, and precisely: *"I'm unclear whether this is because the
  # grades have not saved?"*. That is the collision - this page autosaves every 30s, has a "Save
  # grades" button and a live "Saving..." region a few inches from the pill, and "draft" is the word
  # every other product uses for *unsaved* work (Docs, Gmail, WordPress). A pill next to a save
  # indicator reading "Draft" is asking to be read as save state. Stripe can label an invoice "Draft"
  # because nothing on that screen is autosaving.
  #
  # So the label names the thing that actually distinguishes the states, in the page's own verb: the
  # action is "Finalize this quarter", so the states are not finalized, finalizing, finalized. That
  # cannot be confused with saving, because saving is not finalizing, and it tells a teacher what is
  # outstanding rather than making them learn an enum.
  #
  # "Finalizing" for `verified` is deliberately a *progress* word. Nobody should ever see it:
  # `GradeBooksController#finalize` sets it and calls `DistributeEarnings` in the same request, which
  # sets `completed`. A book sitting in it is one where distribution raised part-way - so the honest
  # label is the thing that was in progress, not a state anyone chose.
  #
  # Both the grade book page and the classroom's list of grade books had their own copy of this
  # mapping, with its own tones hash. Two definitions of one thing is the drift mechanism this
  # codebase keeps rediscovering, so there is now one.
  STATUS_LABELS = {
    "draft" => { label: "Not finalized", tone: :neutral },
    "verified" => { label: "Finalizing", tone: :info },
    "completed" => { label: "Finalized", tone: :success }
  }.freeze

  def grade_book_status(grade_book)
    STATUS_LABELS.fetch(grade_book.status, { label: grade_book.status.to_s.humanize, tone: :neutral })
  end

  # **, forwarded anonymously, so a caller can pass the badge's `class:` through.
  def grade_book_status_badge(grade_book, **)
    status = grade_book_status(grade_book)

    render "components/ui/badge", label: status[:label], tone: status[:tone], **
  end

  # What finalizing does, in one sentence, for **both** the card and the confirmation.
  #
  # It was written out in the card and again, differently, inside the `turbo_confirm` - "Finalize and pay
  # $12.00 to 2 students? This cannot be undone." against "Pays $12.00 into 2 students' portfolios and
  # locks these entries." Two sentences for one consequence is how a preview and the thing it previews
  # come to disagree, which this codebase has recorded for the figures themselves.
  #
  # The possessive is built rather than pluralized: `pluralize` gives "1 student", and interpolating an
  # apostrophe after that produces "1 student' portfolio".
  def finalize_consequence(earnings)
    recipients = earnings.student_count == 1 ? "student's portfolio" : "students' portfolios"

    "Pays #{number_to_currency(earnings.total_cents / 100.0)} into #{earnings.student_count} " \
      "#{recipients} and locks these entries. This cannot be undone."
  end
end
