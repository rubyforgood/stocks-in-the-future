class TickerListComponent < ViewComponent::Base
  def stocks
    [
      {
        change: 0.033,
        name: "Netflix",
        price: 115,
        ticker: "NFLX"
      },
      {
        change: -0.01,
        name: "Sony Corporation",
        price: 58.99,
        ticker: "SNE"
      },
      {
        change: 0.79,
        name: "Under Armour",
        price: 18.07,
        ticker: "AU"
      },
      {
        change: -0.03,
        name: "Ford",
        price: 9.75,
        ticker: "F"
      }
    ]
  end
end
