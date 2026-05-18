class AltchaSolution < ApplicationRecord
  validates :algorithm, :challenge, :salt, :signature, :number, presence: true
  # The Altcha Rails library needs this attr_accessor, don't remove
  attr_accessor :took

  def self.verify_and_save(base64encoded)
    p = begin
      JSON.parse(Base64.decode64(base64encoded))
    rescue StandardError
      nil
    end
    return false if p.nil?

    submission = Altcha::Submission.new(p)
    return false unless submission.valid?

    solution = new(p)

    begin
      solution.save
    rescue ActiveRecord::RecordNotUnique
      # Replay attack
      false
    end
  end

  # To prevent replay attacks, a unique index is enforced on the combination
  # of the fields: algorithm, challenge, salt, signature, and number.
  # This guarantees that each solution can only be saved once (in the given
  # time window). However, to prevent the table from growing indefinitely,
  # we need to periodically delete old solutions. See also the corresponding
  # scheduled job defined in config/schedule.yml.
  def self.cleanup
    AltchaSolution.where(created_at: ...(Time.zone.now - Altcha.timeout)).delete_all
  end
end
