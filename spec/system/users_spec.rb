require "rails_helper"

RSpec.describe "Users", type: :system do
  before do
    driven_by(:rack_test)
  end

  describe "sign up flow" do
    xit "works" do
      visit "/users/sign_up"

      fill_in "Email", with: "test123@test.com"
      fill_in "Password", with: "test123"
      fill_in "Password confirmation", with: "test123"

      expect { click_on "Sign up" }.to change(User, :count).by(1)
    end
  end
end
