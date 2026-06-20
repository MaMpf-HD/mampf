class ReadinessController < ActionController::Base
  def show
    checks = ReadinessCheck.new.call
    healthy = checks.values.all? { |status| status == "ok" }

    render json: { status: healthy ? "ok" : "error", checks: checks },
           status: healthy ? :ok : :service_unavailable
  end
end