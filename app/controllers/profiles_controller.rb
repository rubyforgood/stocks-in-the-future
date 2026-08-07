# frozen_string_literal: true

# Your own account: a display name, an email where the role has one, and a password change.
#
# There was no profile page. `resources :users` routed seven actions to a top-level
# UsersController that had never existed, and the only reachable substitute was Devise's
# registrations#edit, which requires the current password before it will save anything - so
# setting a display name meant proving your password, and a student may have no email to change.
#
# Everything here acts on current_user and nothing takes an id, so there is no object to authorize:
# `authenticate_user!` in ApplicationController is the whole access rule.
class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def password
    @user = current_user

    if @user.update_with_password(password_params)
      # Devise stores part of the password salt in the session, so changing the password signs you
      # out of the request that changed it. registrations#update does the same thing.
      bypass_sign_in(@user)
      redirect_to edit_profile_path, notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # Username is deliberately not here. It is what a student signs in with, and it is assigned by a
  # teacher; letting a child change it silently changes how they log in.
  def profile_params
    params.expect(user: %i[name email])
  end

  def password_params
    params.expect(user: %i[current_password password password_confirmation])
  end
end
