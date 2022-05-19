# TimeStamp class
# plain old ruby class, no active record involved
class TimeStamp
  include ActiveModel::Model

  validates :milliseconds, presence: true
  attr_reader :hours, :minutes, :seconds, :milliseconds

  # extract from YAML
  def self.load(text)
    YAML.safe_load(text, permitted_classes: [TimeStamp,
                                             ActiveModel::Errors],
                         aliases: true) if text.present?
  end

  # store as YAML (for serialization)
  def self.dump(time_stamp)
    time_stamp.to_yaml
  end

  # initialization is possible in several formats:
  # TimeStamp.new(total_seconds: 12345.6)
  # => #<TimeStamp:0x00007fffc0579168 @milliseconds=600, @minutes=25,
  #                                   @seconds=45, @hours=3>
  # TimeStamp.new(time_string: '4:27:17.203')
  # => #<TimeStamp:0x00007fffbb977580 @milliseconds=203, @minutes=27,
  #                                   @seconds=17, @hours=4>
  # TimeStamp.new(h: 3, m: 15, s:20, ms:729)
  # => #<TimeStamp:0x00007fffbc5d1f10 @milliseconds=729, @minutes=15,
  #                                   @seconds=20, @hours=3>
  def initialize(params)
    if params[:total_seconds].present?
      init_with_total_seconds(params[:total_seconds].to_f)
    elsif params[:time_string].present?
      init_with_time_string(params[:time_string])
    else
      init_with_hms(params)
    end
  end

  # The following examples all refer to
  # t = TimeStamp.new(h: 3, m: 15, s:20, ms:729)
  # => #<TimeStamp:0x00007fffbd9799f0 @milliseconds=729, @minutes=15,
  #                                   @seconds=20, @hours=3>

  # t.vtt_string
  # => "03:15:20.729"
  def vtt_string
    format('%02d:%02d:%02d.%03d', @hours, @minutes, @seconds, @milliseconds)
  end

  # t.simple_vtt_string
  # => "3:15:20.729"
  def simple_vtt_string
    format('%01d:%02d:%02d.%03d', @hours, @minutes, @seconds, @milliseconds)
  end

  # t.hms_string
  # => "3h15m20s"
  def hms_string
    format('%01dh%02dm%02ds', @hours, @minutes, @seconds)
  end

  # t.hms_colon_string
  # => "3:15:20"
  def hms_colon_string
    format('%01d:%02d:%02d', @hours, @minutes, @seconds)
  end

  # t.floor_seconds
  # => 11720
  def floor_seconds
    @hours * 3600 + @minutes * 60 + @seconds
  end

  # t.total_seconds
  # => 11720.729
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
