require "rails_helper"

RSpec.describe(Flash, type: :controller) do
  include Turbo::TestAssertions

  controller(ApplicationController) do
    skip_before_action :authenticate_user!

    def test_with_message
      respond_with_flash(:notice, "Success")
    end

    def test_with_block
      respond_with_flash(:notice, "Success") do
        turbo_stream.update("custom-target", html: "<p>content</p>")
      end
    end

    def test_nil_message
      respond_with_flash(:notice, nil, redirect_path: "/some-path") do
        turbo_stream.update("custom-target", html: "<p>content</p>")
      end
    end

    def test_redirect_path
      respond_with_flash(:alert, "Error", redirect_path: "/redirect-destination")
    end

    def test_fallback_location
      respond_with_flash(:alert, "Error", fallback_location: "/fallback-destination")
    end

    def test_render_flash_with_message
      flash.now[:notice] = "Hello" # rubocop:disable Rails/I18nLocaleTexts
      render_flash
    end

    def test_render_flash_empty
      render_flash || head(:ok)
    end
  end

  before do
    routes.draw do
      get "test_with_message" => "anonymous#test_with_message"
      get "test_with_block" => "anonymous#test_with_block"
      get "test_nil_message" => "anonymous#test_nil_message"
      get "test_redirect_path" => "anonymous#test_redirect_path"
      get "test_fallback_location" => "anonymous#test_fallback_location"
      get "test_render_flash_with_message" => "anonymous#test_render_flash_with_message"
      get "test_render_flash_empty" => "anonymous#test_render_flash_empty"
    end
  end

  describe "#respond_with_flash" do
    context "turbo_stream format" do
      it "prepends flash stream when message is present" do
        get :test_with_message, format: :turbo_stream
        assert_turbo_stream action: :prepend, target: "flash-messages"
      end

      it "renders block streams alongside the flash stream" do
        get :test_with_block, format: :turbo_stream
        assert_turbo_stream action: :prepend, target: "flash-messages"
        assert_turbo_stream action: :update, target: "custom-target"
      end

      it "omits flash stream when message is nil" do
        get :test_nil_message, format: :turbo_stream
        assert_no_turbo_stream action: :prepend, target: "flash-messages"
        assert_turbo_stream action: :update, target: "custom-target"
      end
    end

    context "html format" do
      it "hard-redirects to redirect_path when given" do
        get :test_redirect_path
        expect(response).to redirect_to("/redirect-destination")
        expect(flash[:alert]).to eq("Error")
      end

      it "uses redirect_back_or_to when given fallback_location" do
        get :test_fallback_location
        expect(response).to redirect_to("/fallback-destination")
        expect(flash[:alert]).to eq("Error")
      end

      it "does not set flash when message is nil" do
        get :test_nil_message
        expect(response).to redirect_to("/some-path")
        expect(flash[:notice]).to be_nil
      end
    end
  end

  describe "#render_flash" do
    it "renders a prepend stream when flash is set" do
      get :test_render_flash_with_message, format: :turbo_stream
      assert_turbo_stream action: :prepend, target: "flash-messages"
    end

    it "renders nothing when flash is empty" do
      get :test_render_flash_empty, format: :turbo_stream
      assert_no_turbo_stream action: :prepend, target: "flash-messages"
    end
  end
end
