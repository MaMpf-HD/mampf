# What an upload was meant for: who asked, with which uploader, for which
# record -- one that does not exist yet is named by the ids that decide who may
# create it. Signed and short-lived, and no substitute for authorization: the
# endpoint asks the target's ability again when the file arrives.
class UploadIntent
  LIFETIME = 24.hours
  PURPOSE = "upload_intent".freeze
  HEADER = "HTTP_X_UPLOAD_INTENT".freeze

  attr_reader :user_id, :uploader, :target_type, :target_id, :attributes, :action

  def self.mint(user:, uploader_class:, target: nil, action: nil)
    new(user_id: user.id,
        uploader: uploader_class.name,
        target: {
          type: target&.class&.base_class&.name,
          id: target&.id,
          attributes: authorizing_attributes(target)
        },
        action: action || default_action(target)).token
  end

  def self.parse(token)
    return if token.blank?

    payload = verifier.verified(token, purpose: PURPOSE)
    return unless payload.is_a?(Hash)

    new(**payload.deep_symbolize_keys.slice(:user_id, :uploader, :target, :action))
  rescue ArgumentError
    nil
  end

  def self.from_request(request)
    parse(request.get_header(HEADER))
  end

  # Signature intact, lifetime over: worth a different message than a refusal.
  def self.expired?(token)
    token.present? && verifier.valid_message?(token) && parse(token).nil?
  end

  def self.verifier
    Rails.application.message_verifier(PURPOSE)
  end

  # Only the ids: they are what the abilities ask about, and the rest of a
  # half-filled form is none of our business.
  def self.authorizing_attributes(target)
    return {} if target.nil? || target.id.present?

    target.attributes.compact.select { |name, _| name.end_with?("_id", "_type") }
  end

  # The records an upload can be aimed at. A method rather than a frozen
  # constant, because a class kept across a reload goes stale.
  def self.target_classes
    { "Course" => Course, "Medium" => Medium, "Submission" => Submission,
      "Tutorial" => Tutorial, "User" => User }
  end

  def self.default_action(target)
    target&.id ? :update : :create
  end

  def initialize(user_id:, uploader:, target: {}, action: :update)
    @user_id = user_id
    @uploader = uploader
    @target_type = target[:type]
    @target_id = target[:id]
    @attributes = target[:attributes] || {}
    @action = action.to_sym
  end

  def token
    self.class.verifier.generate(
      { user_id: user_id, uploader: uploader, action: action,
        target: { type: target_type, id: target_id, attributes: attributes } },
      purpose: PURPOSE, expires_in: LIFETIME
    )
  end

  def for_user?(user)
    user.present? && user.id == user_id
  end

  def for_uploader?(uploader_class)
    uploader == uploader_class.name
  end

  def target
    return @target if defined?(@target)

    klass = target_class
    @target = target_id ? klass&.find_by(id: target_id) : klass&.new(attributes)
  rescue ActiveModel::UnknownAttributeError
    @target = nil
  end

  def targeted?
    target_type.present?
  end

  private

    def target_class
      self.class.target_classes[target_type]
    end
end
