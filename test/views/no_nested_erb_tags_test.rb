# frozen_string_literal: true

require "test_helper"

# No ERB tag contains another ERB tag.
#
# An ERB tag ends at the first closing delimiter it meets, so a comment placed inside a `render` call's
# argument list ends that call mid-hash. What happens next depends on where the seam falls: a syntax error if
# the remaining Ruby is invalid, or - worse - a valid template that prints the rest of the comment on the
# page as text.
#
# I did this **three times in one sitting**, in `home/_todays_movers`, `stocks/_stocks_table` and
# `stocks/index`. `bin/lint` passes all three: erb_lint tokenises the tags and a nested one produces tokens
# it accepts. `no_leaked_template_syntax_test` catches the leaking variety by reading rendered pages, but it
# needs a browser and it only covers pages it visits.
#
# This is the cheap static half: it reads every template and needs neither.
class NoNestedErbTagsTest < ActiveSupport::TestCase
  OPEN = "#{60.chr}#{37.chr}".freeze # the opening delimiter, built so this file does not contain it
  CLOSE = "#{37.chr}#{62.chr}".freeze

  test "no ERB tag contains another ERB tag" do
    offenders = []

    Rails.root.glob("app/views/**/*.erb").each do |path|
      source = path.read
      offset = 0

      while (start = source.index(OPEN, offset))
        finish = source.index(CLOSE, start + OPEN.length)
        break unless finish

        body = source[(start + OPEN.length)...finish]
        if body.include?(OPEN)
          line = source[0...start].count("\n") + 1
          offenders << "#{path.relative_path_from(Rails.root)}:#{line}"
        end

        offset = finish + CLOSE.length
      end
    end

    assert_empty offenders,
                 "a tag opens inside another tag, so the outer one ends early: #{offenders.join(', ')}"
  end
end
