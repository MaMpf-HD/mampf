class ConsumptionSaver
  include Sidekiq::Worker

  def perform(medium_id, mode, sort)
    Consumption.create(medium_id:,
                       mode:,
                       sort:)
  end
end
