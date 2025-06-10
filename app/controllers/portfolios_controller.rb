# frozen_string_literal: true

class PortfoliosController < ApplicationController
  before_action :set_portfolio

  def show
    @stocks = @portfolio.stocks
  end

  private

  def set_portfolio
    @portfolio = Portfolio.find(params[:id])
  end
end
