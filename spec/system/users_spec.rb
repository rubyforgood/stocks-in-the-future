require "rails_helper"

RSpec.describe "Users", type: :system do
  before do
    driven_by(:rack_test)
  end

  describe "sign up flow" do
    it "works" do
      visit "/users/sign_up"

      fill_in "Email", with: "test123@test.com"
      fill_in "Password", with: "test123"
      fill_in "Password confirmation", with: "test123"

      expect { click_on "Sign up" }.to change(User, :count).by(1)
    end

    context "when the email input is not filled out" do
      it "doesn't change the user count" do
        visit "/users/sign_up"

        fill_in "Email", with: ""
        fill_in "Password", with: "test123"
        fill_in "Password confirmation", with: "test123"

        expect { click_on "Sign up" }.not_to change(User, :count)
        expect(page).to have_content("Email can't be blank")
      end
    end

    context "When the password input is not filled out" do
      it "doesn't change the user count" do
        visit "/users/sign_up"

        fill_in "Email", with: "test123@test.com"
        fill_in "Password", with: ""
        fill_in "Password confirmation", with: "test123"

        expect { click_on "Sign up" }.not_to change(User, :count)
        expect(page).to have_content("Password can't be blank")
      end
    end

    context "When the password confirmation input is not filled out" do
      it "doesn't change the user count" do
        visit "/users/sign_up"

        fill_in "Email", with: "test123@test.com"
        fill_in "Password", with: "test123"
        fill_in "Password confirmation", with: ""

        expect { click_on "Sign up" }.not_to change(User, :count)
        expect(page).to have_content("Password confirmation doesn't match")
      end

      context "When all fields are not filled out" do
        it "doesn't change the user count" do
          visit "/users/sign_up"

          fill_in "Email", with: ""
          fill_in "Password", with: ""
          fill_in "Password confirmation", with: ""

          expect { click_on "Sign up" }.not_to change(User, :count)
          expect(page).to have_content("Email can't be blank Password can't be blank")
        end
      end
    end
  end
end
