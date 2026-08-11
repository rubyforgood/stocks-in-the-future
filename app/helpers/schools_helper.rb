# frozen_string_literal: true

module SchoolsHelper
  # A year's name, with a badge on the one in progress.
  #
  # The list is ordered newest-first, and "newest" is not the year anybody is looking for - it is the one
  # running now. Marking it is what SIS products do: PowerSchool and Infinite Campus both default to and
  # label the active school year rather than leaving you to find it. A badge rather than reordering, because
  # a list of years that is not monotonic is harder to scan than one with a marker in it.
  def year_option_label(year)
    return year.name unless year.current?

    safe_join([year.name, render("components/ui/badge", label: "Current", tone: :info)], " ")
  end
end
