# frozen_string_literal: true

require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  test "recurring configuration file exists and is valid" do
    recurring_file = Rails.root.join("config/recurring.yml")
    assert File.exist?(recurring_file), "config/recurring.yml should exist"

    assert_nothing_raised do
      config = YAML.load_file(recurring_file, aliases: true)
      assert_not_nil config, "recurring.yml should contain valid YAML configuration"
    end
  end

  test "recurring configuration includes required jobs" do
    recurring_file = Rails.root.join("config/recurring.yml")
    content = File.read(recurring_file)

    assert_match(/OrderExecutionJob/, content)
    assert_match(/MonthlyPortfolioSnapshotJob/, content)

    config = YAML.load_file(recurring_file, aliases: true)
    default_config = config["development"] || config["test"] || config["production"]

    assert_not_nil default_config, "Should have configuration for at least one environment"
    assert default_config.key?("daily_order_execution"), "Should include daily_order_execution job"
    assert default_config.key?("monthly_portfolio_snapshot"), "Should include monthly_portfolio_snapshot job"
  end

  test "scheduled job classes exist and can be loaded" do
    assert_nothing_raised do
      StockPricesUpdateJob
    end

    assert_equal ApplicationJob, OrderExecutionJob.superclass
    assert_equal ApplicationJob, MonthlyPortfolioSnapshotJob.superclass
    assert_equal ApplicationJob, StockPricesUpdateJob.superclass
  end
end
