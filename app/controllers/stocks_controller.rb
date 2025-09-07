# frozen_string_literal: true

class StocksController < ApplicationController
  before_action :set_stock, only: %i[show]
  before_action :authenticate_user!
  before_action :set_portfolio

  def index
    @stocks = Stock.active.includes(portfolio_stocks: :portfolio)
    @portfolio = current_user.portfolio if current_user.student?
  end

  def show; end

  private

  def set_portfolio
    @portfolio = current_user.portfolio
  end

  def set_stock
    @stock = Stock.find(params[:id])
  end
end
