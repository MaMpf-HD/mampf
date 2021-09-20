# ItemsController
class InteractionsController < ApplicationController
  authorize_resource
  layout 'administration'

  def current_ability
    @current_ability ||= InteractionAbility.new(current_user)
  end

  def index
  end

  def export_interactions
  	start_date = interaction_params[:start_date].to_date
		end_date = interaction_params[:end_date].to_date
  	@interactions = Interaction.created_between(start_date, end_date)
    respond_to do |format|
      format.html { head :ok }
      format.csv { send_data @interactions.to_csv,
      											 filename: "interactions-from-#{start_date}-to-#{end_date}-at-#{Time.now}.csv" }
    end
  end

  def export_probes
  	start_date = interaction_params[:start_date].to_date
		end_date = interaction_params[:end_date].to_date
  	@probes = Probe.created_between(start_date, end_date)
    respond_to do |format|
      format.html { head :ok }
      format.csv { send_data @probes.to_csv,
      											 filename: "probes-from-#{start_date}-to-#{end_date}-at-#{Time.now}.csv" }
    end
  end

  private

  def interaction_params
  	params.require(:interactions).permit(:start_date, :end_date)
 	end
end