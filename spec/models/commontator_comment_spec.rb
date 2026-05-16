require "rails_helper"

RSpec.describe(Commontator::Comment, type: :model) do
  let(:creator) { FactoryBot.create(:confirmed_user) }
  let(:medium) { FactoryBot.create(:lecture_medium) }
  let(:thread) { medium.commontator_thread }
  let(:double_posted_error) do
    I18n.t("activerecord.errors.models.commontator/comment.attributes.body.double_posted")
  end

  it "adds a single presence error for a blank body" do
    comment = described_class.new(creator: creator, thread: thread, body: nil)

    expect(comment).to be_invalid
    expect(comment.errors[:body].size).to eq(1)
  end

  it "reapplies the body validators idempotently" do
    described_class.validates(:body, uniqueness: {
                                scope: CommontatorCommentPatch::CUSTOM_UNIQUENESS_SCOPE,
                                message: :double_posted
                              })

    CommontatorCommentPatch.apply!

    uniqueness_validators = described_class.validators_on(:body).select do |validator|
      validator.is_a?(ActiveRecord::Validations::UniquenessValidator) &&
        validator.options[:scope] == CommontatorCommentPatch::CUSTOM_UNIQUENESS_SCOPE
    end

    expect(uniqueness_validators.size).to eq(1)

    parent = described_class.create!(
      creator: creator,
      thread: thread,
      body: "Parent"
    )
    described_class.create!(
      creator: creator,
      thread: thread,
      parent: parent,
      body: "Yes"
    )
    duplicate_reply = described_class.new(
      creator: creator,
      thread: thread,
      parent: parent,
      body: "Yes"
    )

    expect(duplicate_reply).to be_invalid
    expect(duplicate_reply.errors[:body]).to eq([double_posted_error])
  end

  it "scopes duplicate reply detection to the same parent" do
    first_parent = described_class.create!(
      creator: creator,
      thread: thread,
      body: "Parent one"
    )
    second_parent = described_class.create!(
      creator: creator,
      thread: thread,
      body: "Parent two"
    )
    described_class.create!(
      creator: creator,
      thread: thread,
      parent: first_parent,
      body: "Yes"
    )

    duplicate_reply = described_class.new(
      creator: creator,
      thread: thread,
      parent: first_parent,
      body: "Yes"
    )
    other_parent_reply = described_class.new(
      creator: creator,
      thread: thread,
      parent: second_parent,
      body: "Yes"
    )

    expect(duplicate_reply).to be_invalid
    expect(duplicate_reply.errors[:body]).to include(double_posted_error)
    expect(other_parent_reply).to be_valid
  end

  it "rejects duplicate top-level comments in the same thread" do
    described_class.create!(
      creator: creator,
      thread: thread,
      body: "Yes"
    )

    duplicate_comment = described_class.new(
      creator: creator,
      thread: thread,
      body: "Yes"
    )

    expect(duplicate_comment).to be_invalid
    expect(duplicate_comment.errors[:body]).to include(double_posted_error)
  end
end
