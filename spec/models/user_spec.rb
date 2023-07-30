require 'rails_helper'

RSpec.describe User, type: :model do
  subject do
    described_class.new(email: "test@test.com", password: "password", password_confirmation: "password", 
    first_name: "John", last_name: "Doe", username: "johndoe")
  end

  it 'is valid with valid attributes' do
    expect(subject).to be_valid
  end

  it 'is not valid without an email' do
    subject.email = nil
    expect(subject).to_not be_valid
  end

  it 'is not valid without a first_name' do
    subject.first_name = nil
    expect(subject).to_not be_valid
  end

  it 'is not valid with a first_name longer than 50 characters' do
    subject.first_name = 'a' * 51
    expect(subject).to_not be_valid
  end

  it 'is not valid without a last_name' do
    subject.last_name = nil
    expect(subject).to_not be_valid
  end

  it 'is not valid with a last_name longer than 50 characters' do
    subject.last_name = 'a' * 51
    expect(subject).to_not be_valid
  end

  it 'is not valid without a username' do
    subject.username = nil
    expect(subject).to_not be_valid
  end

  it 'is not valid with a username longer than 50 characters' do
    subject.username = 'a' * 51
    expect(subject).to_not be_valid
  end

  it 'is not valid if the username is not unique' do
    described_class.create!(email: "test2@test.com", password: "password", password_confirmation: "password", 
    first_name: "John", last_name: "Doe", username: "johndoe")
    expect(subject).to_not be_valid
  end
end
