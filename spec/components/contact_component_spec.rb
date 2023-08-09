require "rails_helper"

RSpec.describe ContactComponent, type: :component do
  it "renders something useful" do
    component = described_class.new
    render_inline(component)

    expect(page).to have_text("STAY CONNECTED TO STOCKS IN THE FUTURE!")
    expect(page).to have_selector(:css, 'a[href="https://sifonline.org/"]')
    expect(page).to have_selector(:css, 'a[href="https://www.facebook.com/StocksintheFuture/"]')
  end
end
