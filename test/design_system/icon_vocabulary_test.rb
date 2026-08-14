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
