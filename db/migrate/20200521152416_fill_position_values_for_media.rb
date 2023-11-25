class FillPositionValuesForMedia < ActiveRecord::Migration[6.0]
  def change
    Course.all.each do |course|
     # rubocop:todo Layout/IndentationWidth
     course.media.order(:id).each_with_index do |medium, index|
        # rubocop:enable Layout/IndentationWidth
        # rubocop:todo Rails/SkipsModelValidations
        medium.update_column :position, index # rubocop:todo Layout/IndentationWidth, Rails/SkipsModelValidations
       # rubocop:enable Rails/SkipsModelValidations
     end
    end
    Lecture.all.each do |lecture|
      lecture.media.order(:id).each_with_index do |medium, index|
       # rubocop:todo Rails/SkipsModelValidations
       medium.update_column :position, index # rubocop:todo Layout/IndentationWidth, Rails/SkipsModelValidations
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
    Lesson.all.each do |lesson|
      lesson.media.order(:id).each_with_index do |medium, index|
       # rubocop:todo Rails/SkipsModelValidations
       medium.update_column :position, index # rubocop:todo Layout/IndentationWidth, Rails/SkipsModelValidations
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
end
