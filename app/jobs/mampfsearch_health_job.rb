class MampfsearchHealthJob < ApplicationJob
  queue_as :default

  def perform
    MampfsearchHealth.new.call
  end
end
