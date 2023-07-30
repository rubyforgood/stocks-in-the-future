require "rails_helper"

RSpec.describe Cohort, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:cohort)).to be_valid
  end
end
