module Vignettes
  module InfoSlidesHelper
    def select_info_slide_icon_path(info_slide)
      case info_slide.icon_type
      when "eye"
        "vignettes/eye.png"
      when "dotplot"
        "vignettes/dotplot.png"
      else
        "vignettes/fallback.svg"
      end
    end
  end
end
