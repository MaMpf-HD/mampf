# InteractionsController
class InteractionsController < ApplicationController
  authorize_resource
  layout "administration"

  def current_ability
    @current_ability ||= InteractionAbility.new(current_user)
  end

  def index
  end

  def export_probes
    start_date = interaction_params[:start_date].to_date
    end_date = interaction_params[:end_date].to_date
    @probes = Probe.created_between(start_date, end_date)
    respond_to do |format|
      format.html { head :ok }
      format.csv do
        send_data(@probes.to_csv,
                  filename: "probes-from-#{start_date}-to-#{end_date}-at-#{Time.zone.now}.csv")
      end
    end
  end

  private

    def interaction_params
      params.expect(interactions: [:start_date, :end_date])
    end
end
