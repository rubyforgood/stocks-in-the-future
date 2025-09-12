# frozen_string_literal: true

require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  test "schedule file exists and is valid" do
    schedule_file = Rails.root.join("config/schedule.rb")
    assert File.exist?(schedule_file), "config/schedule.rb should exist"

    # Verify the file can be loaded without syntax errors
    assert_nothing_raised do
      require "whenever"
      Whenever::JobList.new(file: schedule_file.to_s)
    end
  end

  test "schedule includes both required jobs" do
    schedule_file = Rails.root.join("config/schedule.rb")
    content = File.read(schedule_file)

    # Just verify the job names are mentioned in the file
    assert_match(/StockPricesUpdateJob/, content)
    assert_match(/OrderExecutionJob/, content)
  end
end
