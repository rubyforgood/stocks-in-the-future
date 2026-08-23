# frozen_string_literal: true

# The staging ribbon: which deployment am I looking at.
#
# An admin on staging had nothing on screen telling them the data was not real. A ribbon answers "which
# deployment am I looking at", which is a different question from the component demo's banner - that one
# says "this *page* is not part of the product", and it stays.
#
# **Staging only, never development.** In development the URL already says localhost, and a permanent
# stripe on every page of every working day is noise that teaches you to stop seeing it - which is
# exactly what would make it useless on staging, where it is seen rarely and has to register.
#
# It is a strip above the header rather than a callout in the content, because it describes the whole
# application and not the page - GitLab's environment ribbon and Shopify's development-store banner sit
# in the chrome for the same reason.
#
# **It is dismissible for the rest of the login, and it leaves a badge behind.** This reverses the
# original decision, which was that only an *outcome* removes itself and the environment is still true
# in a minute. That reasoning is sound about the *sentence* and wrong about the strip: reported in use as
# "very distracting, and it pushes everything down", which a 32px band across every page on every visit
# is.
#
# Two things keep the reversal safe, and neither is optional:
#
#   - **It comes back on every login.** The dismissal is a flag in the session, cleared by a Warden
#     `after_authentication` hook, so the band is unmissable at the start of every visit and quiet after
#     that. A permanent dismissal is the mute button this codebase already warns about, and its failure
#     mode is somebody months later acting on staging in the belief that it is real.
#   - **A badge replaces it**, in the header, at zero vertical cost. The question the ribbon answers is
#     still answered; only the 32px band goes. Stripe keeps a persistent "Test mode" pill for the same
#     reason, and a collapsed Salesforce sandbox banner leaves a marker rather than nothing.
#
module EnvironmentHelper
  # Am I on a deployment that should say so at all?
  #
  # Set `PREVIEW_STAGING_CHROME=1` to see it locally, which is the only way anybody has seen it: staging
  # deploys `main` - `config/deploy/staging.rb` sets the branch and the workflow triggers on a push to it -
  # and this ribbon has only ever existed on `stocksdesign`. Chrome gated on one environment is chrome that
  # goes unlooked-at until it deploys, and the flag is what closed that gap: the app side's sidebar sitting
  # 32px behind the header, and the text being unreachable at 200%, were both found through it.
  #
  # An earlier version of this comment said those two were found *on staging*. They were not, and could not
  # have been - see the note in design-todo. Refused in production, where the ribbon would be an outright lie.
  def environment_ribbon?
    return true if ENV["PREVIEW_STAGING_CHROME"] == "1" && !Rails.env.production?

    Rails.env.staging?
  end

  # The full band, unless it has been put away since this login.
  def show_environment_ribbon?
    environment_ribbon? && !session[StagingRibbonDismissal::SESSION_KEY]
  end

  # The badge is what is left after dismissing, so exactly one of the two shows.
  def show_environment_badge?
    environment_ribbon? && !show_environment_ribbon?
  end
end
