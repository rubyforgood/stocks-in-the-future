class PortfoliosController < ApplicationController
    # before_action :authenticate_user!
    before_action :set_user
    before_action :set_portfolio
  
    def show
        @stocks = @portfolio.stocks
    end
  
    private
  
    def set_user
        @user = User.find(params[:user_id])
    end
  
    def set_portfolio
        @portfolio = @user.portfolio
    end
end