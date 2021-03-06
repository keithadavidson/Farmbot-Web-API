require 'spec_helper'

describe Api::UsersController do

  include Devise::Test::ControllerHelpers

  describe '#create' do

    it 'creates a new user' do
      email = Faker::Internet.email
      original_count = User.count
      params =  { password_confirmation: "Password123",
                  password:              "Password123",
                  email:                 email,
                  name:                  "Frank" }
      post :create, params

      expect(User.count).to eq(original_count + 1)
      user = User.find json[:user][:id]
      expect(user.name).to eq("Frank")
      expect(user.email).to eq(email)
      expect(user.valid_password?('Password123')).to be_truthy
      expect(json[:token][:unencoded][:sub]).to eq(user.email)
    end

    it 'handles password confirmation mismatch' do
      email = Faker::Internet.email
      original_count = User.count
      params =  { password_confirmation: "Password123",
                  password:              "Password321",
                  email:                 email,
                  name:                  "Frank" }
      post :create, params
      expect(User.count > original_count).to be_falsy
      expect(json[:password]).to include("do not match")
      expect(response.status).to eq(422)
    end
  end
end
