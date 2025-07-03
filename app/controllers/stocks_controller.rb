# frozen_string_literal: true

class StocksController < ApplicationController
  before_action :set_stock, only: %i[show]
  before_action :set_portfolio
  before_action :authenticate_user!

  def index
    @stocks = Stock.all
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
