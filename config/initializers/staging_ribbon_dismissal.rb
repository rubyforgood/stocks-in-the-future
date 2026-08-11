# frozen_string_literal: true

# The staging band comes back on every login.
#
# Warden runs this after a successful authentication, which is the only moment that means "a new
# login" - `current_sign_in_at` would need trackable, and clearing the flag in a controller would miss
# every path into a session that is not the sign-in form.
#
# It cannot be left to the session expiring on its own: signing out and back in during the same browser
# session must also bring the band back, and Devise's logout does not reliably clear unrelated session
# keys.
#
# Note for anyone changing this file: code reloading covers `app/`, not `config/initializers/`, so a
# running server keeps executing the previous version. Restart before believing that an edit here did
# or did not work.
Warden::Manager.after_authentication do |_user, auth, _opts|
  auth.request.session.delete(StagingRibbonDismissal::SESSION_KEY)
end
