module Mampfsearch
  class Hierarchy
    def self.for(medium)
      lesson = nil
      lecture = nil
      course = nil

      case medium.teachable
      when Lesson
        lesson = medium.teachable
        lecture = lesson.lecture
        course = lecture&.course
      when Talk
        lecture = medium.teachable.lecture
        course = lecture&.course
      when Lecture
        lecture = medium.teachable
        course = lecture.course
      when Course
        course = medium.teachable
      end

      {
        lesson_rails_id: lesson&.id,
        lecture_rails_id: lecture&.id,
        course_rails_id: course&.id
      }
    end
  end
end
