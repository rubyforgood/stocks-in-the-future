# frozen_string_literal: true

# One endpoint for every dismissible banner, replacing a member action per banner on portfolios.
#
# No Pundit call, and that is not an omission: a dismissal is always written for `current_user`, so
# there is no other record to authorise against. The id never comes from the request, which is what a
# policy would otherwise be protecting.
class DismissalsController < ApplicationController
  # The allowlist is the security boundary. Without it this is a write of arbitrary strings into a
  # table, keyed by whatever a client sends.
  def create
    key = params[:key].to_s

    return head(:bad_request) unless Dismissal::KEYS.include?(key)

    current_user.dismiss!(key)

    # Back where they were: these banners appear on more than one page - the trading-off callout is on
    # the trading floor and the portfolio both - and dismissing one should not move you.
    redirect_back_or_to(root_path)
  end
end
