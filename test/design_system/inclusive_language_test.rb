# frozen_string_literal: true

require "test_helper"

# Copy does not presume what the reader can do.
#
# Reported on the admin top bar's **"View site"**, and it was one of eleven: "View all", "View portfolio"
# twice, "View all transactions", two mailers opening "Click on the link", "watch your earnings change",
# "not while you watch it", "who can see this classroom", "they see a note", and "nobody sees it".
#
# Two different failures, and the second is the less arguable one:
#
#   - **A sight verb** presumes the reader looks at a screen. "View" is genuinely contested - Polaris,
#     Primer and Material all still ship it, and it is half a dead metaphor for "access" - but the neutral
#     alternatives are no worse as copy and are often better, because naming the destination ("All
#     transactions") is what GOV.UK asks for anyway and gives a link that still makes sense out of context.
#   - **"Click" presumes a mouse**, and that one is not contested: Microsoft's style guide says use
#     *select*, Google's says the same, and GOV.UK has said "do not use click here" for a decade. This app
#     is used on school Chromebooks with touchscreens, and the two worst instances were in the account
#     mailers - the first sentence a new student ever reads.
#
# Asserted against the source rather than the rendered page because a mailer is not a page and
# `component_demo` is development-only, so a browser walk cannot reach either. A rendered scan over every
# page found nothing this misses, which is the check that this is looking in the right place.
class InclusiveLanguageTest < ActiveSupport::TestCase
  SIGHT = /\b(?:views?|viewing|sees?|seeing|look|looks|watch|watching)\b/i
  POINTER = /\b(?:clicks?|clicking)\b/i
  ABLEIST = /\b(?:blind|deaf|dumb|lame|crazy|insane|cripple[sd]?|handicap(?:ped)?|sanity|spaz|psycho)\b/i
  GENDERED = %r{\b(?:guys|chairman|manpower|man-hours|mankind|freshman|middleman|he/she|his/her|s/he)\b}i
  EXCLUSIONARY = /\b(?:whitelist|blacklist|master|slave|grandfather(?:ed)?)\b/i

  BANNED = {
    SIGHT => "presumes sight - use 'open', 'go to', or name the destination",
    POINTER => "presumes a mouse - use 'select', or name what the link does",
    ABLEIST => "ableist metaphor",
    GENDERED => "gendered - use a role name or 'they'",
    EXCLUSIONARY => "exclusionary technical term"
  }.freeze

  # **"View" as a noun is not the failure**, and this cannot tell the difference. "A read-only view", "list
  # view", "this view" are all a screen rather than a claim about the reader's eyes; the rule is about the
  # verb. Reword where it is easy - "a read-only list" is clearer anyway, which is how both instances so far
  # were resolved - and allowlist with a reason where it is not.
  #
  # Two entries, each with a reason rather than a file name.
  #
  # The price feed does the looking, not the reader, so no wording change would make that sentence more
  # inclusive. And "see you again" is a farewell idiom about meeting, not about eyesight - no style guide
  # flags it, and blind and Deaf people use it as everyone else does. That one is separately *unreachable*:
  # `devise_for :users, skip: %i[registrations]` never routes `registrations#destroy`, and `User#destroy`
  # raises rather than hard-deleting. It is left alone because it is an idiom; being dead copy is a
  # different finding with a different fix.
  ALLOWED = [
    "The ticker is what the price feed looks up",
    "We hope to see you again soon"
  ].freeze

  ALLOWED_RE = Regexp.union(ALLOWED).freeze

  # A comment in this repo is an essay, and it is not copy. So is a Tailwind variant, a Stimulus action and
  # a CSS class - `hover:text-rose-700`, `click->modal#close` and `tw-link-tap` are all machinery.
  NOT_COPY = /hover:|group-hover|\(hover|click->|"click"|'click'|data-action|addEventListener|\.click\(|-tap\b/

  def strip_erb_comments(src)
    src.gsub(/<%#.*?%>/m) { |m| "\n" * m.count("\n") }
  end

  def strip_ruby_comments(src)
    src.lines.map { |l| l.match?(/\A\s*#/) ? "\n" : l }.join
  end

  # Every line that can reach a reader: template text and the string literals inside tags, the locale
  # files, and the string literals in the Ruby that builds copy - breadcrumb labels, flash messages, the
  # summary sentences in `admin_helper`.
  def copy_lines
    lines = []

    Rails.root.glob("app/views/**/*.erb").each do |path|
      strip_erb_comments(path.read).lines.each_with_index do |line, i|
        lines << [path, i + 1, line]
      end
    end

    Rails.root.glob("app/{helpers,controllers,models,services,presenters,policies,form_builders}/**/*.rb")
      .each do |path|
      strip_ruby_comments(path.read).lines.each_with_index do |line, i|
        # Only quoted strings, so `view_context` and `render_to_string` are not mistaken for copy.
        line.scan(/"[^"]*"|'[^']*'/).each { |s| lines << [path, i + 1, s] }
      end
    end

    Rails.root.glob("config/locales/*.yml").each do |path|
      path.read.lines.each_with_index { |line, i| lines << [path, i + 1, line] }
    end

    lines
  end

  test "no copy presumes the reader's sight, hands, or gender" do
    offences = copy_lines.filter_map do |path, number, line|
      next if line.match?(NOT_COPY)
      next if line.match?(ALLOWED_RE)

      pattern, reason = BANNED.find { |rx, _| line.match?(rx) }
      next unless pattern

      rel = path.to_s.delete_prefix(Rails.root.to_s).delete_prefix("/")
      "#{rel}:#{number} #{line.match(pattern)[0].inspect} - #{reason}\n      #{line.strip[0, 110]}"
    end

    assert_empty offences, "Copy presuming what the reader can do:\n  #{offences.join("\n  ")}"
  end

  # The rule the sweep was applied with, pinned so the next person does not have to infer it: a verb about
  # what the *system* does is fine, and only a verb about what the *reader* does is not. "Featured - shown
  # on everyone's home page" survived for that reason, and "Not featured, so nobody sees it" did not.
  test "a verb about the system is not the failure this looks for" do
    assert_no_match SIGHT, "Featured - shown on everyone's home page"
    assert_no_match SIGHT, "Select a column header to sort"
    assert_match SIGHT, "View site"
    assert_match POINTER, "Click the link below to unlock your account"
  end
end
