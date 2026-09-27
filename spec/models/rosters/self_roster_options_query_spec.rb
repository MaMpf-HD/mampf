require "rails_helper"

RSpec.describe(Rosters::SelfRosterOptionsQuery) do
  describe "#call" do
    let(:user) { create(:confirmed_user) }
    let(:lecture) { create(:lecture, :released_for_all) }

    let!(:add_only_tutorial) do
      create(:tutorial,
             lecture: lecture,
             title: "Tutorial A",
             skip_campaigns: true,
             self_materialization_mode: :add_only)
    end

    let!(:add_and_remove_tutorial) do
      create(:tutorial,
             lecture: lecture,
             title: "Tutorial B",
             skip_campaigns: true,
             self_materialization_mode: :add_and_remove)
    end

    let!(:remove_only_tutorial) do
      create(:tutorial,
             lecture: lecture,
             title: "Tutorial C",
             skip_campaigns: true,
             self_materialization_mode: :remove_only)
    end

    let!(:allocated_remove_only_tutorial) do
      create(:tutorial,
             lecture: lecture,
             title: "Tutorial D",
             skip_campaigns: true,
             self_materialization_mode: :remove_only)
    end

    let!(:disabled_tutorial) do
      create(:tutorial,
             lecture: lecture,
             title: "Tutorial E",
             skip_campaigns: true,
             self_materialization_mode: :disabled)
    end

    before do
      allocated_remove_only_tutorial.add_user_to_roster!(user)
    end

    it "returns joinable rosterables and withdraw-only rosterables the user can leave" do
      result = described_class.new(lecture, user).call

      expect(result).to contain_exactly(
        add_only_tutorial,
        add_and_remove_tutorial,
        allocated_remove_only_tutorial
      )
    end

    it "offers nothing to the teacher, who runs the registration" do
      result = described_class.new(lecture, lecture.teacher).call

      expect(result).to be_empty
    end

    it "offers nothing while the lecture is unpublished" do
      lecture.update!(released: nil)

      expect(described_class.new(lecture, user).call).to be_empty
    end

    it "keeps the talks in program order, the user's own and full ones included" do
      seminar = create(:seminar, :released_for_all)
      talks = (1..3).map do |position|
        create(:talk, lecture: seminar, position: position, capacity: 1,
                      skip_campaigns: true, self_materialization_mode: :add_and_remove)
      end
      talks.first.add_user_to_roster!(create(:confirmed_user))
      talks.second.add_user_to_roster!(user)

      expect(described_class.new(seminar, user).call).to eq(talks)
    end

    it "still returns visible options when the user is in a join-only tutorial" do
      blocked_user = create(:confirmed_user)
      add_only_tutorial.add_user_to_roster!(blocked_user)

      result = described_class.new(lecture, blocked_user).call

      expect(result).to contain_exactly(
        add_only_tutorial,
        add_and_remove_tutorial
      )
    end
  end
end
