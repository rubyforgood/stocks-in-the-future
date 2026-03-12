# frozen_string_literal: true

# test/mailers/previews/devise_mailer_preview.rb

class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(User.first || User.new(email: "test@example.com"), "faketoken")
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(User.first || User.new(email: "test@example.com"), "faketoken")
  end

  def unlock_instructions
    Devise::Mailer.unlock_instructions(User.first || User.new(email: "test@example.com"), "faketoken")
  end

  def email_changed
    Devise::Mailer.email_changed(User.first || User.new(email: "test@example.com"))
  end

  def password_change
    Devise::Mailer.password_change(User.first || User.new(email: "test@example.com"))
  end
end
