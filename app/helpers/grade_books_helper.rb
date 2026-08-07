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
end
