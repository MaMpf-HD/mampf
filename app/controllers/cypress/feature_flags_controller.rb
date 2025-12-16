module Cypress
  class FeatureFlagsController < CypressController
    def enable
      Flipper.enable(params[:name].to_sym)
      render json: { name: params[:name], enabled: true }, status: :created
    end

    def disable
      Flipper.disable(params[:name].to_sym)
      render json: { name: params[:name], enabled: false }, status: :created
    end
  end
end
