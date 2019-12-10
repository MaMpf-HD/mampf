# ItemsController
class InteractionsController < ApplicationController
  authorize_resource

  def index
    @interactions = Interaction.all

    respond_to do |format|
      format.html { head :ok }
      format.csv { send_data @interactions.to_csv, filename: "interactions-#{Time.now}.csv" }
    end
  end
end