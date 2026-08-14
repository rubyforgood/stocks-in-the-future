# frozen_string_literal: true

require "test_helper"

# One action, one glyph - checked against the source, because the rendered SVG does not say which icon it is.
#
# `lucide_icon` emits a bare `<svg>` with no name, no class and no data attribute, so a browser test can
# only compare path data. The pairing is declared at the call site, which is where this reads it.
#
# Reported: "Deactivate" carried **four** icons - `user-x` in the shared helper, `ban` on the teachers
# index, `archive` on the users index left over from the rename, and `trash-2` on the teacher record page,
# where it sat beside a genuine "Permanently delete" wearing the same glyph. One icon meant both
# "reversible, they keep everything" and "gone". "Edit" had two and "Reactivate" had two.
class IconVocabularyTest < ActiveSupport::TestCase
  SOURCES = Rails.root.glob("app/views/**/*.erb") + Rails.root.glob("app/helpers/**/*.rb")

  # `ghost_action_link "Label", ..., icon: "name"`, and the block form where a `lucide_icon` line is
  # followed by the label on its own line.
  ACTION_WITH_ICON = /
    ghost_action_(?:link|button)\s+(?:action_label\(\s*)?"([^"]+)"
    [^\n]*(?:\n[^\n]*){0,4}?icon:\s*"([a-z0-9-]+)"
  /x
  ICON_ABOVE_LABEL = /lucide_icon\(?\s*"([a-z0-9-]+)"[^\n]*\n\s*([A-Z][A-Za-z ]{2,24})\n/

  def icons_by_label
    pairs = SOURCES.flat_map do |path|
      src = File.read(path)
      src.scan(ACTION_WITH_ICON).map { |label, icon| [label, icon, path] } +
        src.scan(ICON_ABOVE_LABEL).map { |icon, label| [label.strip, icon, path] }
    end

    pairs.each_with_object({}) do |(label, icon, path), out|
      (out[label] ||= {})[icon] ||= []
      out[label][icon] << path.to_s.delete_prefix(Rails.root.to_s).delete_prefix("/")
    end
  end

  def admin_nav
    src = Rails.root.join("app/views/admin/shared/_navigation.html.erb").read
    src.scan(/\{[^}]*?label:\s*"([^"]+)"[^}]*?icon:\s*"([a-z0-9-]+)"[^}]*?\}/m).to_h
  end

  # The app navbar writes each item as a `nav_item` render with the glyph a line or two away, rather than
  # as a hash, so it is read positionally.
  def app_nav
    lines = Rails.root.join("app/views/layouts/_navbar.html.erb").read.lines
    lines.each_with_object({}).with_index do |(line, out), i|
      label = line[/label:\s*"([^"]+)"/, 1]
      next unless label

      window = lines[[0, i - 4].max..(i + 4)].join
      icon = window[/lucide_icon\("([a-z0-9-]+)"/, 1]
      out[label] = icon if icon
    end
  end

  # A sidebar's icons exist to tell its items apart, so two items sharing one is the whole failure.
  # `presentation` served **Classrooms and Teachers** in the same list.
  test "no navigation glyph is used for two items in the same nav" do
    [["admin", admin_nav], ["app", app_nav]].each do |name, nav|
      repeated = nav.values.tally.select { |_icon, count| count > 1 }.keys

      assert_empty repeated,
                   "#{name} nav: #{repeated.inspect} labels more than one item - " \
                   "#{nav.select { |_l, i| repeated.include?(i) }.inspect}"
    end
  end

  # **Both halves, one idea, one glyph.** Transactions was `receipt` on the app navbar and
  # `arrow-left-right` on the admin sidebar; Classes was a hand-written Heroicons path against the admin
  # half's `presentation`; the trading floor was `chart-no-axes-combined` against `chart-line`.
  test "an idea that appears in both navs uses the same glyph" do
    admin = admin_nav
    app = app_nav

    { "Dashboard" => "Home", "Classrooms" => "Classes",
      "Stocks" => "Trading floor", "Transactions" => "Transactions" }.each do |admin_label, app_label|
      assert_equal admin[admin_label], app[app_label],
                   "#{admin_label} and #{app_label} are the same idea on the two halves and should carry " \
                   "the same glyph"
    end
  end

  # The app navbar hand-wrote one item's SVG, which is why it fell out of every icon inventory: nothing
  # greps a path definition.
  test "every navbar item draws its glyph through lucide_icon" do
    src = Rails.root.join("app/views/layouts/_navbar.html.erb").read

    assert_equal app_nav.size, src.scan("lucide_icon(").size - src.scan('lucide_icon("chevron-down"').size,
                 "a navbar item is drawing its own SVG; every icon in the app comes from `lucide_icon`"
  end

  # An empty state's icon is the concept's own glyph - the one the nav and the section use - so it says what
  # is missing rather than filling the space. **"No students yet" carried three**: `graduation-cap` on the
  # classroom roster, `users` on the grade book, and the partial's default `inbox` on the admin list. Three
  # more titles carried two, and twelve of twenty empty states were on the default, so the fallback was
  # doing most of the work and doing it inconsistently.
  #
  # `Nothing to show` is the exception and stays on the default: it is the gallery demonstrating the
  # component, with no concept behind it.
  GENERIC_EMPTY_STATE = "Nothing to show"

  def empty_states
    SOURCES.flat_map do |path|
      text = path.read
      text.to_enum(:scan, /(?:empty_state|empty_row)/).map { Regexp.last_match.begin(0) }.filter_map do |i|
        seg = text[i, 900].split("<% end %>").first.to_s
        title = seg[/title:\s*"([^"]{2,60})"/, 1]
        next unless title

        [title, seg[/\bicon:\s*"([a-z0-9-]+)"/, 1] || "inbox (default)"]
      end
    end.uniq
  end

  test "no empty state title carries two different icons" do
    by_title = empty_states.each_with_object({}) { |(title, icon), out| (out[title] ||= Set.new) << icon }
    offenders = by_title.select { |_title, icons| icons.size > 1 }

    assert_empty offenders, offenders.map { |t, i| "#{t.inspect}: #{i.to_a.sort.inspect}" }.join("\n")
  end

  test "every empty state names its glyph" do
    on_default = empty_states.select { |title, icon| icon.include?("default") && title != GENERIC_EMPTY_STATE }

    assert_empty on_default.map(&:first),
                 "these fall through to `inbox`: #{on_default.map(&:first).inspect}. An empty state carries " \
                 "the glyph of the thing that is missing - the same one its nav item and its section use."
  end

  test "no action label carries two different icons" do
    offenders = icons_by_label.select { |_label, icons| icons.size > 1 }

    assert_empty offenders.keys,
                 offenders.map { |label, icons|
                   "#{label.inspect}: " + icons.map { |icon, paths| "#{icon} (#{paths.first})" }.join(", ")
                 }.join("\n")
  end

  # The pairs that carry the deactivate/archive split, spelled out so the split survives a refactor: a
  # **person** gets a `user-*` glyph, a **thing** gets `archive` / `rotate-ccw`.
  test "the people actions and the thing actions use their own glyphs" do
    icons = icons_by_label

    { "Deactivate" => "user-x", "Reactivate" => "user-check",
      "Archive" => "archive", "Restore" => "rotate-ccw",
      "Edit" => "pencil", "Delete" => "trash-2" }.each do |label, expected|
      next if icons[label].nil?

      assert_equal [expected], icons[label].keys,
                   "#{label} should be #{expected}: a person is deactivated and reactivated, a thing is " \
                   "archived and restored, and the glyphs say which."
    end
  end
end
