require "rails_helper"

RSpec.describe "layouts/application", type: :feature do
  before do
    visit root_path
  end

  xit "renders the apple icon on teacher home page" do
    # need help getting this test to work
    click_link "TEACHER"

    expect(page).to have_content("Home")
    expect(page).to have_selector("img", class: "teacher-icon", count: 1)
    expect(page).to have_content("Student")
    expect(page).to have_content("About SIF")
  end
end
