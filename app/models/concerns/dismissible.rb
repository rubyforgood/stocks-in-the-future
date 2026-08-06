# frozen_string_literal: true

# Asking and answering "has this person dismissed that?".
#
# The `since:` argument is the whole reason this is not a boolean column, and it is easy to leave out
# by accident, so: **pass it for any banner whose condition can recur.** Without it a dismissal is
# permanent, which is right for a one-off - the first-share celebration happens once and is then over -
# and wrong for a state a teacher can switch off, switch on and switch off again. With it, the
# dismissal covers the instance of the condition it was made against and nothing later.
module Dismissible
  extend ActiveSupport::Concern

  included do
    has_many :dismissals, dependent: :destroy
  end

  # `since` is when the condition being dismissed began. nil means either "this cannot recur" or "we do
  # not know when it began" - the second happens because onset columns were not backfilled - and both
  # honour the dismissal. The first real onset makes the comparison exact, so it heals itself.
  def dismissed?(key, since: nil)
    at = dismissals.where(key: key).pick(:dismissed_at)
    return false if at.nil?

    since.nil? || at > since
  end

  # Idempotent, and it moves the date forward on a second dismissal rather than keeping the first: if a
  # condition recurred and the reader dismissed it again, the later date is the true one.
  def dismiss!(key)
    dismissal = dismissals.find_or_initialize_by(key: key)
    dismissal.dismissed_at = Time.current
    dismissal.save!
  end
end
