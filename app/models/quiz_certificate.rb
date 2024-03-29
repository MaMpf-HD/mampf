class QuizCertificate < ApplicationRecord
  belongs_to :quiz, class_name: "Medium", inverse_of: :quiz_certificates
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
