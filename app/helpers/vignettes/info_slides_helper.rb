module Vignettes
  module InfoSlidesHelper
    def select_info_slide_icon_path(info_slide)
      case info_slide.icon_type
      when "eye"
        "vignettes/eye.svg"
      when "dotplot"
        "vignettes/dotplot.svg"
      when "media"
        "vignettes/media.svg"
      else
        "vignettes/fallback.svg"
      end
    end
  end
end
