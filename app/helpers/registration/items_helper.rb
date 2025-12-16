module Registration
  module ItemsHelper
    def format_capacity(capacity)
      if capacity.nil?
        t("basics.unlimited")
      else
        "#{capacity} #{t("basics.seats")}"
      end
    end
  end
end
