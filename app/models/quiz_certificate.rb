class QuizCertificate < ApplicationRecord
  belongs_to :quiz, class_name: 'Medium', foreign_key: 'quiz_id'
  belongs_to :user, optional: true

  before_create :set_code

  def self.generate_code
    loop do
      random_code = SecureRandom.base58(6)
      break random_code unless QuizCertificate.exists?(code: random_code)
    end
  end

  private

  def set_code
    self.code = QuizCertificate.generate_code
  end
end
