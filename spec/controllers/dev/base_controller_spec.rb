require "rails_helper"

RSpec.describe(Dev::BaseController, type: :controller) do
  controller(Dev::BaseController) do
    skip_before_action :authenticate_user!

    def index
      head :ok
    end
  end

  before do
    routes.draw do
      get "index" => "dev/base#index"
    end
  end

  describe "#verify_development_environment" do
    before do
      allow(Rails.env).to receive(:development?).and_return(true)
    end

    it "allows loopback hosts" do
      ["127.0.0.1", "[::1]", "localhost"].each do |host|
        request.host = host
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    it "rejects non-local hosts" do
      request.host = "example.com"

      expect { get(:index) }.to raise_error(
        ActionController::RoutingError,
        "Not Found"
      )
    end
  end
end
