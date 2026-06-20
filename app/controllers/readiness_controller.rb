class ReadinessController < ApplicationController
  def show
    checks = ReadinessCheck.new.call
    healthy = checks.values.all?("ok")

    render json: { status: healthy ? "ok" : "error", checks: checks },
           status: healthy ? :ok : :service_unavailable
  end
end
