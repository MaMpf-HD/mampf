module Cypress
  # Allows to travel to a date in the backend via Cypress tests.

  class TimecopController < CypressController
    # Travels to a specific date and time.
    #
    # Time is passed as local time. If you want to pass a UTC time, set the
    # parameter `use_utc` to true.
    def travel
      new_time = if params[:use_utc] == "true"
        Time.utc(params[:year], params[:month], params[:day],
                 params[:hours], params[:minutes], params[:seconds])
      else
        Time.zone.local(params[:year], params[:month], params[:day],
                        params[:hours], params[:minutes], params[:seconds])
      end

      render json: Timecop.travel(new_time), status: :created
    end

    def reset
      render json: Timecop.return, status: :created
    end
  end
end
