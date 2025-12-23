# frozen_string_literal: true

module AdminV2
  class YearsController < BaseController
    before_action :set_year, only: %i[show edit update destroy]

    def index
      @years = apply_sorting(Year.all, default: "name")

      @breadcrumbs = [
        { label: "Years" }
      ]
    end

    def show
      @breadcrumbs = [
        { label: "Years", path: admin_v2_years_path },
        { label: @year.name }
      ]
    end

    def new
      @year = Year.new
      @breadcrumbs = [
        { label: "Years", path: admin_v2_years_path },
        { label: "New Year" }
      ]
    end

    def edit
      @breadcrumbs = [
        { label: "Years", path: admin_v2_years_path },
        { label: @year.name, path: admin_v2_year_path(@year) },
        { label: "Edit" }
      ]
    end

    def create
      @year = Year.new(year_params)

      if @year.save
        redirect_to admin_v2_year_path(@year), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Years", path: admin_v2_years_path },
          { label: "New Year" }
        ]
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @year.update(year_params)
        redirect_to admin_v2_year_path(@year), notice: t(".notice")
      else
        @breadcrumbs = [
          { label: "Years", path: admin_v2_years_path },
          { label: @year.name, path: admin_v2_year_path(@year) },
          { label: "Edit" }
        ]
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @year.destroy
      redirect_to admin_v2_years_path, notice: t(".notice")
    end

    private

    def set_year
      @year = Year.find(params[:id])
    end

    def year_params
      params.expect(year: [:name])
    end
  end
end
