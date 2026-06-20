class ReadinessController < ActionController::API
  # Keep this endpoint unauthenticated so deploy preflight can probe a new
  # container before it becomes live. External access is restricted at the
  # NGINX edge instead of by the Rails app.
  def show
    checks = ReadinessCheck.new.call
    healthy = checks.values.all?("ok")

    render json: { status: healthy ? "ok" : "error", checks: checks },
           status: healthy ? :ok : :service_unavailable
  end
end
