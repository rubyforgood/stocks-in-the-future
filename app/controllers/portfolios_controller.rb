# frozen_string_literal: true

class PortfoliosController < ApplicationController
  before_action :set_portfolio
  before_action :authenticate_user!

  def show
    authorize @portfolio
    @stocks = @portfolio.stocks
  end

  private

  def set_portfolio
    @portfolio = Portfolio.find(params[:id])
  end
end
