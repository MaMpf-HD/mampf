class TeachableParser

  # params is a hash with keys :all_teachables, :teachable_ids
  # all_teachables is '1' if all teachables in the DB are to be returned
  # teachable ids is an array made up of strings composed of 'lecture-'
  # or 'course-' followed by the id
  def initalize(params)
    @all_teachables = params[:all_teachables] == '1'
    @teachable_ids = search_params[:teachable_ids] || []
  end

  # returns all courses, lectures and lessons that are associated
  # (with inheritance) to the given list of teachables
  # search is done with inheritance:
  # it returns all courses, lectures and lessons that are associated
  # (with inheritance) to the geiven list of teachables
  def teachables_with_inheritance
    return Course.all + Lecture.all + Lesson.all if @all_teachables

    courses + lectures_with_inheritance + lessons_with_inheritance
  end

  def inherited_teachables_as_strings
    return unless @teachable_ids.any?

    teachables_with_inheritance.map { |t| "#{t.class}-#{t.id}" }
  end

  private

  def lecture_ids
    @teachable_ids.select { |t| t.start_with?('Lecture') }
                  .map { |t| t.remove('Lecture-') }
  end

  def lectures
    Lecture.where(id: lecture_ids)
  end

  def course_ids
    @teachable_ids.select { |t| t.start_with?('Course') }
                  .map { |t| t.remove('Course-') }
  end

  def courses
    Course.where(id: course_ids)
  end

  def inherited_lectures_from_courses
    Lecture.where(course: courses)
  end

  def lectures_with_inheritance
    (lectures + inherited_lectures_from_courses).uniq
  end

  def lessons_with_inheritance
    lectures_with_inheritance.collect(&:lessons).flatten
  end
end