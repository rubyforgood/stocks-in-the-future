# frozen_string_literal: true

module AdminV2
  class AnnouncementsController < BaseController
    before_action :set_announcement, only: %i[show edit update destroy]

    def index
      @announcements = Announcement.latest

      # Apply sorting if params present
      if params[:sort].present?
        direction = params[:direction] == "desc" ? :desc : :asc
        @announcements = @announcements.order(params[:sort] => direction)
      end

      @breadcrumbs = [
        { label: "Announcements" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Announcements", path: admin_v2_announcements_path },
        { label: @announcement.title }
      ]
    end

    def new
      @announcement = Announcement.new
      @breadcrumbs = [
        { label: "Announcements", path: admin_v2_announcements_path },
        { label: "New Announcement" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Announcements", path: admin_v2_announcements_path },
        { label: @announcement.title, path: admin_v2_announcement_path(@announcement) },
        { label: "Edit" }
      ]
    end

    def create
      @announcement = Announcement.new(announcement_params)

      if @announcement.save
        redirect_to admin_v2_announcement_path(@announcement), notice: "Announcement created successfully."
      else
        @breadcrumbs = [
          { label: "Announcements", path: admin_v2_announcements_path },
          { label: "New Announcement" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @announcement.update(announcement_params)
        redirect_to admin_v2_announcement_path(@announcement), notice: "Announcement updated successfully."
      else
        @breadcrumbs = [
          { label: "Announcements", path: admin_v2_announcements_path },
          { label: @announcement.title, path: admin_v2_announcement_path(@announcement) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @announcement.destroy
      redirect_to admin_v2_announcements_path, notice: "Announcement deleted successfully."
    end

    private

    def set_announcement
      @announcement = Announcement.find(params[:id])
    end

    def announcement_params
      params.expect(announcement: %i[title content featured])
    end
  end
end
