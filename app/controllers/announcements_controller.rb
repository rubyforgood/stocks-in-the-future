# frozen_string_literal: true

class AnnouncementsController < ApplicationController
  before_action :set_announcement, only: %i[show]

  def show; end

  private

  def set_announcement
    @announcement = Announcement.find(params.expect(:id))
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("announcements.not_found")
  end
end
