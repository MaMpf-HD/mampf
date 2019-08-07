class Clicker < ApplicationRecord
  belongs_to :teachable, polymorphic: true, optional: true
  belongs_to :editor, class_name: 'User'
  belongs_to :question, optional: true

  before_create :set_code

  validates :title, uniqueness: { scope: [:editor_id] }
  validates :title, presence: true

  def user_link
    clicker_url(self, host: 'localhost').gsub('clickers','c')
  end

  def editor_link
    clicker_url(self,
                host: 'localhost',
                params: { code: code }).gsub('clickers','c')
  end

  private

  def set_code
    self.code = SecureRandom.uuid
  end
end
