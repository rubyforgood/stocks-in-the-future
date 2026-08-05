# frozen_string_literal: true

require "test_helper"

# Gradients and arbitrary values, checked against the source rather than the browser.
#
# Neither is a rendering bug, so no visual test catches them - they just quietly mean one surface
# belongs to no system. The home page's "Earnings to invest" hero was the app's only gradient, and
# its two tokens had exactly one caller between them.
#
# Arbitrary values are allowed where the scale genuinely has no answer, and the allowlist below is
# the whole set. Everything else had a scale value available: 300px is h-75, 400px is w-100, 480px is
# max-h-120, 80px is min-h-20, 36px is min-h-9. Four of those were inline `style` attributes rather
# than classes, which is the same thing wearing a different hat.
class NoArbitraryValuesTest < ActiveSupport::TestCase
  SOURCES = Rails.root.glob("app/{views,helpers,form_builders,components}/**/*.{erb,rb}") +
            Rails.root.glob("app/assets/tailwind/*.css")

  # Arbitrary values with no equivalent on any scale.
  ALLOWED = [
    # Hides the native <details> triangle. There is no utility for a vendor pseudo-element.
    "[&::-webkit-details-marker]:hidden",
    # An ::after pseudo-element needs content to exist at all; this is the toggle switch's knob.
    "after:content-['']",
    # Tailwind's border widths are 0/1/2/4/8. The nav's leading indicator is 3px by design.
    "border-l-[3px]",
    # The sidebar fills the viewport below the 64px fixed header. calc() has no scale equivalent.
    "h-[calc(100vh-4rem)]"
  ].freeze

  # Whole comment blocks, not just lines that begin with a marker. These comments quote the code they
  # replaced - `style="max-width: 510px"`, `data-[state=checked]` - so a line-based filter reports the
  # documentation as the offence, which is exactly what the first version of this test did.
  def sources_without_comments
    SOURCES.reject { |f| f.to_s.include?("component_demo") }.map do |file|
      body = file.read
      body = body.gsub(/<%#.*?%>/m, "")     # ERB comment blocks
      body = body.gsub(%r{/\*.*?\*/}m, "")  # CSS comment blocks
      body = body.lines.reject { |line| line.strip.start_with?("#", "//") }.join
      [file.relative_path_from(Rails.root).to_s, body]
    end
  end

  test "nothing uses a gradient" do
    offenders = sources_without_comments.select { |_, body| body.include?("gradient") }.map(&:first)

    assert_empty offenders,
                 "a gradient is a surface that belongs to no system: every other surface here is " \
                 "white, slate-50 or a named tint"
  end

  test "no view sets an inline style attribute" do
    offenders = sources_without_comments.filter_map { |path, body| path if body.match?(/\sstyle="/) }

    assert_empty offenders,
                 "an inline style is an arbitrary value that no sweep for classes will find. " \
                 "300px is h-75, 400px is w-100, 36px is min-h-9"
  end

  test "arbitrary values are limited to the ones with no scale equivalent" do
    pattern = /(?:^|\s|")([a-z:&-]*\[[^\]\s"]+\][a-z:-]*)/
    found = {}

    sources_without_comments.each do |path, body|
      body.scan(/class(?:=|:\s*)"([^"]*)"/).flatten.each do |classes|
        classes.scan(pattern).flatten.each do |value|
          # Ruby hash access inside an interpolated class string, not a Tailwind value.
          next if value.match?(/\A[a-z_]+\[:/)
          next if ALLOWED.include?(value)

          (found[value] ||= []) << path
        end
      end
    end

    assert_empty found,
                 "arbitrary values with a scale equivalent: " \
                 "#{found.map { |v, f| "#{v} (#{f.uniq.join(', ')})" }.join('; ')}"
  end
end
