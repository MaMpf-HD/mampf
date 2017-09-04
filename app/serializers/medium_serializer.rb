class MediumSerializer < ActiveModel::Serializer
  attributes :embedded_video
  def embedded_video
    unless object.video_file_link.nil?
      aspect_ratio = object.width.to_f / object.height
      width = @instance_options[:width]
      if width != nil then
        height = (width.to_i/aspect_ratio).to_i.to_s
        dimensions = 'width="' + width + '" height="' + height +'"'
      else
        dimensions = ''
      end
      html =  ['<video ', dimensions, ' controls><source src="',
               object.video_file_link, '" type="video/mp4"></video>']
      html.join
    end
   end
   def passed
     @instance_options[:width]
   end
end
