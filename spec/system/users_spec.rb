require "rails_helper"

RSpec.describe "Users", type: :system do
  before do
    driven_by(:rack_test)
  end

  describe "sign up flow" do
    let(:user) { FactoryBot.create(:user) }

    it "works" do
      visit "/users/sign_in"

      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
      click_on "Log in"

      expect(page.current_path).to eq(root_path)
    end
  end
end
