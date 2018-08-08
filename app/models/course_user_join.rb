class CourseUserJoin < ApplicationRecord
  belongs_to :course
  belongs_to :user
  validate :nonempty?

  def kaviar
    return unless course.kaviar?
    user.lectures.where(id: course.lectures).present?
  end

  def nonempty?
    return true if kaviar
    course.available_extras.each do |e|
      return true if self.public_send(e)
    end
    errors.add(:base, 'Für einen abonnierten Kurs müssen Inhalte ausgewählt werden.')
    false
  end

end
