# TimeStamp class
class TimeStamp
  include ActiveModel::Model

  validates :milliseconds, presence: { message: 'Invalid timestamp.' }
  attr_reader :hours, :minutes, :seconds, :milliseconds

  def self.load(text)
    YAML.load(text) if text.present?
  end

  def self.dump(time_stamp)
    time_stamp.to_yaml
  end

  def initialize(params)
    if params[:total_seconds].present?
      init_with_total_seconds(params[:total_seconds].to_f)
    elsif params[:time_string].present?
      init_with_time_string(params[:time_string])
    else
      init_with_hms(params)
    end
  end

  def vtt_string
    format('%02d:%02d:%02d.%03d', @hours, @minutes, @seconds, @milliseconds)
  end

  def simple_vtt_string
    format('%01d:%02d:%02d.%03d', @hours, @minutes, @seconds, @milliseconds)
  end

  def hms_string
    format('%01dh%02dm%02ds', @hours, @minutes, @seconds)
  end

  def hms_colon_string
    format('%01d:%02d:%02d', @hours, @minutes, @seconds)
  end

  def floor_seconds
    @hours * 3600 + @minutes * 60 + @seconds
  end

  def total_seconds
    floor_seconds + @milliseconds / 1000.0
  end

  private

  def init_with_total_seconds(total_s)
    floor_s = total_s.floor
    @milliseconds = ((total_s - floor_s) * 1000).round
    @minutes = (floor_s / 60) % 60
    @seconds = floor_s % 60
    @hours = floor_s / (60 * 60)
  end

  def init_with_time_string(time_string)
    return unless /(\d+):([0-5]\d):([0-5]\d).(\d{3})/.match?(time_string)
    matchdata = /(\d):([0-5]\d):([0-5]\d).(\d{3})/.match(time_string)
    @hours = matchdata[1].to_i
    @minutes = matchdata[2].to_i
    @seconds = matchdata[3].to_i
    @milliseconds = matchdata[4].to_i
  end

  def init_with_hms(params)
    @hours = params[:h].to_i
    @minutes = params[:m].to_i
    @seconds = params[:s].to_i
    @milliseconds = params[:ms].to_i
  end
end
