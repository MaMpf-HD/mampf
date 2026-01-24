require "rails_helper"
require_relative "../../../app/models/rosters/stream_service"

RSpec.describe(Rosters::StreamService) do
  let(:lecture) { create(:lecture) }
  # Mocking view_context to capture turbo streams
  let(:view_context) { double("ViewContext") }
  let(:service) { described_class.new(lecture, view_context) }
  let(:turbo_stream_builder) { double("TurboStreamBuilder") }

  before do
    # helper for turbo_stream
    allow(view_context).to receive(:turbo_stream).and_return(turbo_stream_builder)

    # Differentiate returns based on target (first arg)
    allow(turbo_stream_builder).to receive(:replace).with("roster_groups", anything)
                                                    .and_return("<replace-roster></replace-roster>")
    allow(turbo_stream_builder).to receive(:replace).with("item_1",
                                                          anything)
                                                    .and_return("<replace-item></replace-item>")
    allow(turbo_stream_builder).to receive(:prepend).with("flash-messages",
                                                          anything)
                                                    .and_return("<prepend-flash></prepend-flash>")

    # Fallback for others
    allow(turbo_stream_builder)
      .to receive(:replace).with(no_args)
                           .and_return("<turbo-stream action='replace'></turbo-stream>")

    # helper for lecture_roster_path
    allow(view_context).to receive(:lecture_roster_path)
      .and_return("/lectures/#{lecture.id}/roster")
    # helper for dom_id
    allow(ActionView::RecordIdentifier).to receive(:dom_id).and_return("item_1")
    # helper for turbo_frame_tag (mocking simplified output)
    allow(view_context).to receive(:turbo_frame_tag).and_return("<turbo-frame></turbo-frame>")
  end

  describe "#roster_changed" do
    it "returns a stream to replace the roster_groups frame" do
      streams = service.roster_changed

      expect(streams).to include("<replace-roster></replace-roster>")
    end

    it "includes flash stream if flash is provided" do
      streams = service.roster_changed(flash: { notice: "Saved" })

      expect(streams).to include("<prepend-flash></prepend-flash>")
    end
  end

  describe "#item_updated" do
    context "when item structure has not changed" do
      let(:item) { create(:tutorial, lecture: lecture) }

      before do
        allow(item).to receive(:previous_changes).and_return({})
      end

      it "returns a stream to replace the item tile" do
        streams = service.item_updated(item)
        expect(streams).to include("<replace-item></replace-item>")
      end
    end

    context "when structural change occurred (propagate_to_lecture changed)" do
      let(:cohort) { create(:cohort, context: lecture) }

      before do
        allow(cohort).to receive(:saved_change_to_propagate_to_lecture?).and_return(true)
      end

      it "calls roster_changed" do
        # Expectation that it delegates to roster_changed (which returns the mocked stream)
        expect(service.item_updated(cohort)).to include("<replace-roster></replace-roster>")
      end
    end
  end
end
