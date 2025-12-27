require "rails_helper"

RSpec.describe(SpeakerTalkJoin, type: :model) do
  it "has a valid factory" do
    expect(build(:speaker_talk_join)).to be_valid
  end
end
