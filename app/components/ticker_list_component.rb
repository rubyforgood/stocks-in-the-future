class TickerListComponent < ViewComponent::Base
  def initialize(stocks:)
    @stocks = stocks
  end
end
