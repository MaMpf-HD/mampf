module Vignettes
  module InfoSlidesHelper
    def select_info_slide_icon_path(info_slide)
      case info_slide.icon_type
      when "eye"
        "images/vignettes/eye.svg"
      when "dotplot"
        "images/vignettes/dotplot.svg"
      when "media"
        "images/vignettes/media.svg"
      else
        "images/vignettes/fallback.svg"
      end
    end
  end
end
