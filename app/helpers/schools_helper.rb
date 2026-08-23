# frozen_string_literal: true

module SchoolsHelper
  # A year's name, marked when it is the one in progress.
  #
  # The list is ordered newest-first, and "newest" is not the year anybody is looking for - it is the one
  # running now. Marking it is what SIS products do: PowerSchool and Infinite Campus both default to and
  # label the active school year rather than leaving you to find it.
  #
  # **Plain text, not a badge.** This feeds a `<select>`'s option, and an option cannot carry markup - a
  # badge there renders as escaped HTML or is stripped, depending on the browser. The badge is still used
  # where there is an element to put it in: the list rows on the school's page.
  def year_option_text(year)
    year.current? ? "#{year.name} (current)" : year.name
  end
end
