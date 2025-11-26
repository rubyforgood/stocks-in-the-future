# frozen_string_literal: true

require "test_helper"

class NavbarPolicyVisibilityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    classroom = create(:classroom)
    @student = User.create!(username: "student", type: "Student", password: "password", classroom: classroom)
    @teacher = User.create!(username: "teacher", type: "Teacher", password: "password", email: "teacher@test.com")
    @admin = User.create!(username: "admin", type: "Teacher", admin: true, password: "password",
                          email: "admin@test.com")
    @portfolio = Portfolio.create!(user: @student)
  end

  test "student sees My Portfolio if permitted" do
    sign_in @student
    get root_path
    assert_select "a", text: "My Portfolio"
  end

  test "teacher sees Classes if permitted" do
    sign_in @teacher
    get root_path
    assert_select "a", text: "Classes"
  end

  test "admin sees Admin if permitted" do
    sign_in @admin
    get root_path
    assert_select "a", text: "Admin"
  end

  test "navbar shows only active stocks" do
    active_stock = create(:stock, archived: false, ticker: "AAPL")
    archived_stock = create(:stock, archived: true, ticker: "DEAD")

    sign_in @student
    get root_path

    assert_select "p", text: active_stock.ticker
    assert_select "p", text: archived_stock.ticker, count: 0
  end

  test "navbar stocks are displayed in trading floor dropdown" do
    active_stock1 = create(:stock, archived: false, ticker: "AAPL")
    active_stock2 = create(:stock, archived: false, ticker: "GOOGL")
    archived_stock = create(:stock, archived: true, ticker: "DEAD")

    sign_in @student
    get root_path

    assert_select "details[data-controller='stock-navbar-toggle']" do
      assert_select "p", text: active_stock1.ticker
      assert_select "p", text: active_stock2.ticker
    end

    assert_select "details[data-controller='stock-navbar-toggle']" do
      assert_select "p", text: archived_stock.ticker, count: 0
    end
  end

  test "navbar stocks link to correct stock paths" do
    active_stock = create(:stock, archived: false, ticker: "AAPL")

    sign_in @student
    get root_path

    assert_select "a[href='#{stock_path(active_stock)}']" do
      assert_select "p", text: active_stock.ticker
    end
  end
end
