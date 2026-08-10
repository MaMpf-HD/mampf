module GtileIconHelper
  GTILE_ICON_MAP = {
    "person" => "bi-person",
    "location" => "bi-geo-alt",
    "looks_one" => "bi-list-ol",
    "description" => "bi-card-text",
    "event" => "bi-calendar-event"
  }.freeze

  private

    def gtile_icon_for(icon_name)
      GTILE_ICON_MAP.fetch(icon_name, "bi-tag")
    end
end
