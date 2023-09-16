require "rails_helper"

RSpec.describe AcademicYear, type: :model do
  it "has a valid factory" do
    expect(build(:academic_year)).to be_valid
  end
end
