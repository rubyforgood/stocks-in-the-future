# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @current_announcement = Announcement.current
  end
end
