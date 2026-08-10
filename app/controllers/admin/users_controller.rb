# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    include SoftDeletableFiltering

    before_action :set_user, only: %i[show edit update destroy restore]

    # The same discard filter the students list has. Without it this list showed active users only, so a
    # discarded user was not merely un-restorable - there was no screen anywhere that listed them.
    def index
      @users = apply_sorting(scoped_by_discard_status(User), default: "username")

      @breadcrumbs = [
        { label: "Users" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Users", path: admin_users_path },
        { label: @user.username }
      ]
    end

    def new
      @user = User.new

      @breadcrumbs = [
        { label: "Users", path: admin_users_path },
        { label: "New user" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Users", path: admin_users_path },
        { label: @user.username, path: admin_user_path(@user) },
        { label: "Edit" }
      ]
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to admin_user_path(@user), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Users", path: admin_users_path },
          { label: "New user" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Users", path: admin_users_path },
          { label: @user.username, path: admin_user_path(@user) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    # `discard`, not `destroy`. User#destroy calls soft_delete_guard, which **raises** outside
    # production and only then falls through to discard - so this action returned a 500 for every
    # admin who tried it in development, and in production soft-deleted while the confirmation said
    # "This cannot be undone". Nothing tested it. The guard exists to force this call, so make it.
    # The way back from `destroy`, which discards. It covers every type at once, including the two that
    # have their own - a Student restored here is the same row `admin/students#restore` would undiscard.
    def restore
      @user.undiscard
      redirect_to admin_users_path(discarded: true),
                  notice: "#{@user.display_name} has been restored."
    end

    def destroy
      @user.discard
      redirect_to admin_users_path, notice: t(".notice")
    end

    private

    def set_user
      @user = User.find(params.expect(:id))
    end

    def user_params
      params.expect(user: %i[username email type admin classroom_id password password_confirmation])
    end
  end
end
