class ConsumptionSaver
  include Sidekiq::Worker

  def perform(medium_id, mode, sort)
    Consumption.create(medium_id: medium_id,
                       mode: mode,
                       sort: sort)
  end
end