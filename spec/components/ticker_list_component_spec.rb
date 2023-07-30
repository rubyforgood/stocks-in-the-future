require "rails_helper"

RSpec.describe TickerListComponent, type: :component do
  it "renders each stock" do
    described_class.new.stocks.each do |stock|
      expect(stock).to have_key :change
      expect(stock).to have_key :name
      expect(stock).to have_key :price
      expect(stock).to have_key :ticker
    end
  end
end
