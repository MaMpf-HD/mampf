# rubocop:disable Style/StringConcatenation, Security/Open, Rails
class ImportFilesToShrine < ActiveRecord::Migration[5.2]
  def change
    Medium.all.each do |m|
      if m.video_thumbnail_link.present?
        screenshot = open(m.video_thumbnail_link)
        file = Tempfile.new([m.title + "-", ".png"])
        file.binmode
        file.write open(screenshot).read
        file.rewind
        m.update(screenshot: file)
      end
      if m.manuscript_link.present?
        manuscript = open(m.manuscript_link)
        file = Tempfile.new([m.title + "-", ".pdf"])
        file.binmode
        file.write open(manuscript).read
        file.rewind
        m.update(manuscript: file)
      end
      next unless m.video_file_link.present?

      video = open(m.video_file_link)
      file = Tempfile.new([m.title + "-", ".mp4"])
      file.binmode
      file.write open(video).read
      file.rewind
      m.update(video: file)
    end
  end
end
# rubocop:enable Style/StringConcatenation, Security/Open, Rails
