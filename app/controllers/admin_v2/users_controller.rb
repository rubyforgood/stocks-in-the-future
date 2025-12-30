# frozen_string_literal: true

module AdminV2
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = apply_sorting(User.all, default: "username")

      @breadcrumbs = [
        { label: "Users" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Users", path: admin_v2_users_path },
        { label: @user.username }
      ]
    end

    def new
      @user = User.new

      @breadcrumbs = [
        { label: "Users", path: admin_v2_users_path },
        { label: "New User" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Users", path: admin_v2_users_path },
        { label: @user.username, path: admin_v2_user_path(@user) },
        { label: "Edit" }
      ]
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to admin_v2_user_path(@user), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Users", path: admin_v2_users_path },
          { label: "New User" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @user.update(user_params)
        redirect_to admin_v2_user_path(@user), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Users", path: admin_v2_users_path },
          { label: @user.username, path: admin_v2_user_path(@user) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @user.destroy
      redirect_to admin_v2_users_path, notice: t(".notice")
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
