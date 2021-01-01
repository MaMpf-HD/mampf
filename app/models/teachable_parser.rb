# frozen_string_literal: true

# Teachable parser class
# This is a service PORO model that is used in the media search
class TeachableParser
  # params is a hash with key :teachable_ids
  # teachable ids is an array made up of strings composed of 'Lecture-'
  # or 'Course-' followed by the id
  def initialize(params)
    @teachable_ids = params[:teachable_ids] || []
    @all_teachables = params[:all_teachables] == '1'
    @inheritance = params[:teachable_inheritance] == '1'
  end

  # returns all courses, lectures and lessons that are associated
  # to the given list of teachables
  # depending on the teachable_inheritance parameter, this is done with or
  # without inheritance (without inheritance just meaning that the input
  # array of teachable_ids is returned)
  # if the all_teachable flag is set to '1', it returns []
  # results are returned in the form of strings:
  # e.g. as ['Course-5', 'Lecture-2', 'Lesson-39']
  def teachables_as_strings
    return [] if @all_teachables
    return @teachable_ids unless @inheritance

    teachables_with_inheritance.map { |t| "#{t.class}-#{t.id}" }
  end

  private

    def lecture_ids
      @teachable_ids.select { |t| t.start_with?('Lecture') }
                    .map { |t| t.remove('Lecture-') }.map(&:to_i)
    end

    def lectures
      Lecture.where(id: lecture_ids)
    end

    def course_ids
      @teachable_ids.select { |t| t.start_with?('Course') }
                    .map { |t| t.remove('Course-') }.map(&:to_i)
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

    def teachables_with_inheritance
      courses + lectures_with_inheritance + lessons_with_inheritance
    end
end
