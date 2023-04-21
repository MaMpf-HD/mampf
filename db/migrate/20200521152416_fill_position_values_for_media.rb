class FillPositionValuesForMedia < ActiveRecord::Migration[6.0]
  def change
  	Course.all.each do |course|
  		course.media.order(:id).each_with_index do |medium, index|
    		medium.update_column :position, index
    	end
    end
  	Lecture.all.each do |lecture|
  		lecture.media.order(:id).each_with_index do |medium, index|
    		medium.update_column :position, index
    	end
    end
  	Lesson.all.each do |lesson|
  		lesson.media.order(:id).each_with_index do |medium, index|
    		medium.update_column :position, index
    	end
    end
  end
end
