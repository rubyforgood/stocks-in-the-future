require "rails_helper"

RSpec.describe Cohort, type: :model do
  it "has a valid factory" do
    expect(build(:cohort)).to be_valid
  end
end
