module Registration
  module ItemsHelper
    def registration_items_service(campaign)
      @registration_items_service ||= Registration::AvailableItemsService.new(campaign)
    end

    def format_capacity(capacity)
      if capacity.nil?
        t("basics.unlimited")
      else
        "#{capacity} #{t("basics.seats")}"
      end
    end
  end
end
