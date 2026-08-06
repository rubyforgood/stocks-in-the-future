# frozen_string_literal: true

class PortfoliosController < ApplicationController
  before_action :set_portfolio
  before_action :authenticate_user!

  def show
    authorize @portfolio
    @stocks = @portfolio.stocks
    @earnings_summary = EarningsSummary.new(@portfolio)
    @insights = PortfolioInsights.new(@portfolio)
  end

  # Dismisses the first-share message, which shows once. Authorised with the same policy as show:
  # only someone who may see this portfolio may dismiss its message.
  def acknowledge_first_share
    authorize @portfolio, :show?
    @portfolio.acknowledge_first_share!

    redirect_back_or_to(@portfolio.path)
  end

  # redirect_back_or_to, because this callout appears on two pages - the trading floor and the
  # portfolio - and a dismissal should leave you where you were rather than moving you.
  def dismiss_trading_off
    authorize @portfolio, :show?
    @portfolio.dismiss_trading_off!

    redirect_back_or_to(@portfolio.path)
  end

  private

  def set_portfolio
    @portfolio = Portfolio.find(params.expect(:id))
  end
end
