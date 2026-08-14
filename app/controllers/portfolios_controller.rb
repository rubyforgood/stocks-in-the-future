# frozen_string_literal: true

class PortfoliosController < ApplicationController
  before_action :set_portfolio
  before_action :authenticate_user!

  def show
    authorize @portfolio
    @stocks = @portfolio.stocks
    @earnings_summary = EarningsSummary.new(@portfolio)
    @insights = PortfolioInsights.new(@portfolio)
    @breadcrumbs = breadcrumbs_for(@portfolio)
  end

  private

  def set_portfolio
    @portfolio = Portfolio.find(params.expect(:id))
  end

  # **Where you came from, which is not the same page for every reader.**
  #
  # The owner reached this from the navbar's "My portfolio", so it is top-level for them and the partial
  # drops a trail of one. A teacher arrived from their classroom roster, where the student's name is the
  # link; an admin from `admin/students#show`, whose "Open portfolio" button is the only link out of that
  # page - and neither had any way back, because this page renders in the app layout and the app layout had
  # no trail at all.
  def breadcrumbs_for(portfolio)
    owner = portfolio.user
    title = "#{owner.display_name}'s portfolio"

    if current_user.admin?
      [{ label: "Students", path: admin_students_path },
       { label: owner.display_name, path: helpers.user_show_path(owner) },
       { label: title }]
    elsif current_user.teacher? && owner.classroom.present?
      [{ label: "Classes", path: classrooms_path },
       { label: owner.classroom.name, path: classroom_path(owner.classroom) },
       { label: title }]
    else
      []
    end
  end
end
