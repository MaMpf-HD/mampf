require "rails_helper"

RSpec.describe(Current) do
  let(:user) { FactoryBot.create(:confirmed_user) }

  describe ".user" do
    it "returns the current user" do
      Current.user = :user
      expect(Current.user).to eq(:user)
    end
  end

  describe "current_user= via ApplicationController" do
    it "sets the current user" do
      ApplicationController.current_user = :user
      expect(Current.user).to eq(:user)
    end
  end
end
