# frozen_string_literal: true

# Initials avatars for people. Never for status - design.md is explicit about that.
#
# Initials rather than uploaded images on purpose: the users here are schoolchildren, so
# photographs would be a data-protection question rather than a design one.
#
# The tone is derived from the name so a person keeps the same colour on every screen,
# using String#sum rather than a hash of the id: it is stable across environments, and
# seeded and production records with the same name look the same.
#
# Every pair is a 100 background with 800 text. design.md's example used 700, which also
# clears 4.5:1, but the avatar text is text-xs so the extra margin is worth having - and
# these are decorative-adjacent, which is exactly where contrast tends to get overlooked.
module AvatarHelper
  AVATAR_TONES = [
    "bg-sky-100 text-sky-800",
    "bg-emerald-100 text-emerald-800",
    "bg-violet-100 text-violet-800",
    "bg-amber-100 text-amber-800",
    "bg-rose-100 text-rose-800",
    "bg-teal-100 text-teal-800"
  ].freeze

  # One letter for a single-word name, two for a name that separates into parts. Usernames
  # here are usually one word, so a single initial is the common case.
  def avatar_initials(user)
    parts = user.display_name.to_s.split(/[\s._-]+/).reject(&:empty?)
    return "?" if parts.empty?

    if parts.size >= 2
      "#{parts[0][0]}#{parts[1][0]}".upcase
    else
      parts[0][0].upcase
    end
  end

  def avatar_tone(user)
    AVATAR_TONES[user.display_name.to_s.sum % AVATAR_TONES.size]
  end

  # aria-hidden because the initials repeat the name that sits beside them, or the visually
  # hidden name in an avatar-only control. Announcing "A" adds nothing.
  def avatar_tag(user, size: "h-9 w-9")
    tag.span(
      avatar_initials(user),
      class: "grid #{size} shrink-0 place-items-center rounded-full text-xs " \
             "font-semibold #{avatar_tone(user)}",
      aria: { hidden: true }
    )
  end
end
