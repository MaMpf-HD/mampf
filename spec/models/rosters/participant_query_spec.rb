require "rails_helper"

RSpec.describe(Rosters::ParticipantQuery, type: :model) do
  let(:lecture) { create(:lecture) }
  let(:params) { {} }
  subject { described_class.new(lecture, params).call }

  describe "#call" do
    let!(:user1) { create(:confirmed_user, name: "Alice", name_in_tutorials: "Zalice") }
    let!(:user2) { create(:confirmed_user, name: "Bob") }
    let!(:user3) { create(:confirmed_user, name: "Charlie") }

    before do
      # Enroll all users in the lecture
      create(:lecture_membership, user: user1, lecture: lecture)
      create(:lecture_membership, user: user2, lecture: lecture)
      create(:lecture_membership, user: user3, lecture: lecture)
    end

    it "returns a result object" do
      expect(subject).to be_a(Rosters::ParticipantQuery::Result)
      expect(subject.total_count).to eq(3)
      expect(subject.filter_mode).to eq("all")
    end

    describe "searching" do
      before do
        user2.update!(first_name: "Ada", last_name: "Lovelace", matriculation_number: "3456789")
      end

      it "finds a participant by the real name the row shows" do
        result = described_class.new(lecture, search: "Ada Lovelace").call

        expect(result.scope.map(&:user)).to eq([user2])
      end

      it "finds a participant by matriculation number" do
        result = described_class.new(lecture, search: "3456789").call

        expect(result.scope.map(&:user)).to eq([user2])
      end

      it "sorts by last name, and by the shown name without one" do
        expect(subject.scope.map(&:user)).to eq([user3, user2, user1])
      end
    end

    describe "counts" do
      # We need separate tests or separate lectures for tutorials and talks
      # because a seminar cannot have tutorials, and a lecture cannot have talks

      context "with tutorials" do
        let(:lecture) { create(:lecture) }
        let(:tutorial) { create(:tutorial, lecture: lecture) }

        before do
          create(:tutorial_membership, tutorial: tutorial, user: user1)
          # user2 and user3 unassigned
        end

        it "calculates correct counts" do
          expect(subject.total_count).to eq(3)
          expect(subject.unassigned_count).to eq(2)
        end
      end

      context "with talks" do
        let(:lecture) { create(:lecture, :is_seminar) }
        let(:talk) { create(:talk, lecture: lecture) }

        before do
          create(:speaker_talk_join, talk: talk, speaker: user2)
          # user1 and user3 unassigned
        end

        it "calculates correct counts" do
          expect(subject.total_count).to eq(3)
          expect(subject.unassigned_count).to eq(2)
        end
      end
    end

    describe "filtering" do
      context "when filter is 'all'" do
        let(:params) { { filter: "all" } }

        it "returns all participants" do
          expect(subject.scope.count).to eq(3)
        end
      end

      context "when filter is 'unassigned'" do
        let(:params) { { filter: "unassigned" } }
        let(:tutorial) { create(:tutorial, lecture: lecture) }

        before do
          create(:tutorial_membership, tutorial: tutorial, user: user1)
        end

        it "returns only unassigned participants" do
          expect(subject.scope.map(&:user)).to contain_exactly(user2, user3)
          expect(subject.scope.count).to eq(2)
        end
      end
    end

    describe "sorting" do
      # Without first and last name: name_in_tutorials if present, otherwise name
      # user1: Name "Alice", TutName "Zalice" -> Sort key "Zalice"
      # user2: Name "Bob", TutName nil -> Sort key "Bob"
      # user3: Name "Charlie", TutName nil -> Sort key "Charlie"
      # Expected order: Bob, Charlie, Alice (Zalice)

      it "sorts by name_in_tutorials if present, otherwise name" do
        expected_order = [user2, user3, user1]
        expect(subject.scope.map(&:user)).to eq(expected_order)
      end

      it "sorts by last name before first name, umlauts with their base letter" do
        user1.update!(first_name: "Zoe", last_name: "Özdemir")
        user2.update!(first_name: "Anna", last_name: "Peters")
        user3.update!(first_name: "Ben", last_name: "Adams")

        expect(subject.scope.map(&:user)).to eq([user3, user1, user2])
      end

      it "puts someone known by first name alone before a last name that equals it" do
        user1.update!(first_name: "Max", last_name: nil)
        user2.update!(first_name: "Ada", last_name: "Max")
        user3.update!(first_name: "Ben", last_name: "Adams")

        expect(subject.scope.map(&:user)).to eq([user3, user1, user2])
      end
    end
  end
end
