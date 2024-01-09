class Annotation < ApplicationRecord
  belongs_to :medium
  belongs_to :user
  belongs_to :public_comment, class_name: "Commontator::Comment",
                              optional: true

  scope :commented, -> { where.not(public_comment_id: nil) }

  # the timestamp for the annotation position is serialized as text in the db
  serialize :timestamp, TimeStamp

  enum category: { note: 0, content: 1, mistake: 2, presentation: 3 }
  enum subcategory: { definition: 0, argument: 1, strategy: 2 }

  def get_comment # rubocop:todo Naming/AccessorMethodName
    return comment if public_comment_id.nil?

    commontator_comment = Commontator::Comment.find_by(id: public_comment_id).body
  end

  def nearby?(other_timestamp, radius)
    (timestamp.total_seconds - other_timestamp).abs < radius
  end

  def self.colors
    # Colors must have 6 digits and be capitalized (!)
    color_map = {
      1 => "#DB2828",
      2 => "#F2711C",
      3 => "#FBBD08",
      4 => "#B5CC18",
      5 => "#21BA45",
      6 => "#00B5AD",
      7 => "#2185D0",
      8 => "#6435C9",
      9 => "#A333C8",
      10 => "#E03997",
      11 => "#D05D41",
      12 => "#924129",
      13 => "#444444",
      14 => "#999999",
      15 => "#EEEEEE"
    }
  end
end
