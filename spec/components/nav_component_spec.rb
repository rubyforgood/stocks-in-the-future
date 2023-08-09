require "rails_helper"

RSpec.describe NavComponent, type: :component do
  before do
    component = described_class.new
    render_inline(component)
  end

  it "renders something useful" do
    # Uncomment when applicable
    # expect(page).to have_selector(:css, 'a[href="LOGIN URL"]')
    # expect(page).to have_selector(:css, 'a[href="CONTACT US URL"]')
    # expect(page).to have_selector(:css, 'a[href="FAQ URL"]')

    logo = page.find(:xpath, "//img[@class='logo']")
    expect(logo["alt"]).to eq("Stocks In The Future Logo")

    expect(page).to have_selector("img", class: "home-icon", count: 1)
    expect(page).to have_content("Teacher")
    expect(page).to have_content("Student")
    expect(page).to have_content("About SIF")

    # expect(page).to have_selector(:css, 'a[href="STOCK INFO URL"]')
    # expect(page).to have_selector(:css, 'a[href="CURRENT NEWS URL"]')
  end
end
