# frozen_string_literal: true

class StocksController < ApplicationController
  before_action :set_stock, only: %i[show]
  before_action :set_portfolio, only: %i[index show], if: :user_is_student?
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

  def user_is_student?
    current_user.student?
  end
end
