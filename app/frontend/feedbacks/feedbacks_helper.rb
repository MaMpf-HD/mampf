# Draws the pixel-art muffin of the feedback button.
module FeedbacksHelper
  # Draws a pixel grid at the given offset, one rect per run of a color.
  def muffin_pixels(rows, left: 0, top: 0)
    safe_join(rows.each_with_index.flat_map do |row, y|
      x = left
      row.chars.chunk_while { |a, b| a == b }.filter_map do |run|
        unless run.first == "."
          rect = tag.rect(class: "feedback-muffin__#{run.first}",
                          x: x, y: top + y, width: run.size, height: 1)
        end
        x += run.size
        rect
      end
    end)
  end
end
