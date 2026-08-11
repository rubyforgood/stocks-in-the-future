# frozen_string_literal: true

# Not an ActiveRecord model: the staging band's dismissal lives in the session, and this is the one
# place its key is written down.
#
# It is a class rather than a bare string in the controller because three places need to agree on it -
# the controller that sets it, the helper that reads it, and the Warden hook that clears it on
# authentication. A typo in any one of them would be a dismiss button that silently does nothing, which
# is the failure this codebase already records for `Dismissal::KEYS`.
class StagingRibbonDismissal
  SESSION_KEY = :staging_ribbon_dismissed
end
