# frozen_string_literal: true

class AnnouncementsController < ApplicationController
  before_action :set_announcement, only: %i[show]

  # **No trail.** An announcement's only parent is Home, which is a navbar item, so a trail here would be
  # "Home > this page" - one level, which is the case Carbon names outright and the case that had every
  # admin index rendering its own title twice. The partial would drop it anyway; not building it says so.
  def show; end

  private

  def set_announcement
    @announcement = Announcement.find(params.expect(:id))
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("announcements.not_found")
  end
end
