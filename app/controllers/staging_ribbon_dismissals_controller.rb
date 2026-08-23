# frozen_string_literal: true

# Puts the staging band away for the rest of this login.
#
# **Why the session and not the `dismissals` table.** That table holds one persistent row per user per
# key, which is right for "I have seen the first-share celebration" and wrong here: the requirement is
# that the band returns on every login, and a row would have to be compared against something to
# achieve that. The session already expires exactly when we want the dismissal to.
#
# A round trip rather than a Stimulus controller, for the reason this codebase records about callouts: a
# client-side hide of page state that is still true brings it straight back on the next load and reads
# as broken. Here the round trip is also what lets the band be *absent* from the next render, which is
# what reclaims the 32px.
class StagingRibbonDismissalsController < ApplicationController
  # No authentication filter: the sign-in page shows the band too, and somebody reading it there should
  # be able to put it away just the same. There is nothing to authorise - the only thing written is a
  # boolean in the reader's own session.
  skip_before_action :authenticate_user!, raise: false

  def create
    session[StagingRibbonDismissal::SESSION_KEY] = true
    redirect_back_or_to(root_path)
  end
end
