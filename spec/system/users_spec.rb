require "rails_helper"

RSpec.describe "Users", type: :system do
  before do
    driven_by(:rack_test)
  end

  let(:sign_in_url) { "/users/sign_in" }
  let(:visit_login_route) { visit sign_in_url }
  let(:user) { FactoryBot.create(:user) }

  describe "sign in flow" do
    context "when input fields are correctly filled" do
      it "logs in the user" do
        visit_login_route

        fill_in "Email", with: user.email
        fill_in "Password", with: user.password
        click_on "Log in"

        expect(page.current_path).to eq(root_path)
      end
    end

    context "when email input is empty" do
      it "does not login the user" do
        visit_login_route

        fill_in "Email", with: ""
        fill_in "Password", with: user.password
        click_on "Log in"

        expect(page.current_path).to eq(sign_in_url)
        expect(page.status_code).to eq(422)
      end
    end

    context "when password input is empty" do
      it "does not login the user" do
        visit_login_route

        fill_in "Email", with: user.email
        fill_in "Password", with: ""
        click_on "Log in"

        expect(page.current_path).to eq(sign_in_url)
        expect(page.status_code).to eq(422)
      end
    end

    context "when email and password inputs are empty" do
      it "does not login the user" do
        visit_login_route

        fill_in "Email", with: ""
        fill_in "Password", with: ""
        click_on "Log in"

        expect(page.current_path).to eq(sign_in_url)
        expect(page.status_code).to eq(422)
      end
    end
  end

  describe "forgot password flow" do
    context "when email is correct" do
      it "does send a password reset email" do
        visit_login_route

        click_link "Forgot your password?"
        fill_in "Email", with: user.email

        expect { click_on "Send me reset password instructions" }.to change(ActionMailer::Base.deliveries, :count).by(1)
        expect(page.current_path).to eq(sign_in_url)
      end
    end

    context "when the email address does not exist in the db" do
      it "does not send the password reset email" do
        visit_login_route

        click_link "Forgot your password?"
        fill_in "Email", with: "email_does_not_exist@email.com"

        expect { click_on "Send me reset password instructions" }.not_to change(ActionMailer::Base.deliveries, :count)
        expect(page).to have_content("Email not found")
      end
    end

    context "when the email address input is empty" do
      it "does not send the password reset email" do
        visit_login_route

        click_link "Forgot your password?"
        fill_in "Email", with: ""

        expect { click_on "Send me reset password instructions" }.not_to change(ActionMailer::Base.deliveries, :count)
        expect(page).to have_content("Email can't be blank")
      end
    end
  end
end
