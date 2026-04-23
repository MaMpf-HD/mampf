require "rails_helper"

RSpec.describe("Dev::ImpersonateController") do
  describe "POST /dev/impersonate/:id" do
    it "is not routable outside of development" do
      impersonate_routes = Rails.application.routes.routes.select do |r|
        r.path.spec.to_s.include?("dev/impersonate")
      end
      expect(impersonate_routes).to be_empty
    end
  end
end
