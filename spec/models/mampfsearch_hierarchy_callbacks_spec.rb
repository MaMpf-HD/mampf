require "rails_helper"

RSpec.describe("MampfSearch hierarchy callbacks", :mampfsearch) do
  it "queues a completed medium when its teachable changes" do
    medium = FactoryBot.create(:lecture_medium, :with_video,
                               transcription_status: :completed)
    new_lecture = FactoryBot.create(:lecture)
    expect(MampfsearchMetadataSyncJob).to receive(:perform_later).with(medium.id)

    medium.update!(teachable: new_lecture)
  end

  it "queues affected media when a lecture moves to another course" do
    medium = FactoryBot.create(:lesson_medium, :with_video,
                               transcription_status: :completed)
    lecture = medium.teachable.lecture
    expect(MampfsearchMetadataSyncJob).to receive(:perform_later).with(medium.id)

    lecture.update!(course: FactoryBot.create(:course))
  end

  it "queues affected media when a lesson moves to another lecture" do
    medium = FactoryBot.create(:lesson_medium, :with_video,
                               transcription_status: :completed)
    expect(MampfsearchMetadataSyncJob).to receive(:perform_later).with(medium.id)

    medium.teachable.update!(lecture: FactoryBot.create(:lecture))
  end

  it "queues affected media when a talk moves to another lecture" do
    medium = FactoryBot.create(:talk_medium, :with_video,
                               transcription_status: :completed)
    expect(MampfsearchMetadataSyncJob).to receive(:perform_later).with(medium.id)

    medium.teachable.update!(lecture: FactoryBot.create(:lecture, :is_seminar))
  end
end
