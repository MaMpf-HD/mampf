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

      it "finds a participant by the display name when the row shows it" do
        result = described_class.new(lecture, search: "Charlie").call

        expect(result.scope.map(&:user)).to eq([user3])
      end

      it "ignores a display name the row does not show" do
        expect(described_class.new(lecture, search: "Bob").call.scope).to be_empty
      end

      it "takes a percent sign or an underscore in the search literally" do
        expect(described_class.new(lecture, search: "A_a").call.scope).to be_empty
        expect(described_class.new(lecture, search: "%").call.scope).to be_empty
      end

      it "ignores the email address" do
        user3.update!(email: "someone19@example.com")

        expect(described_class.new(lecture, search: "19").call.scope).to be_empty
      end

      it "sorts by last name, and by the shown name without one" do
        expect(subject.scope.map(&:user)).to eq([user3, user2, user1])
      end
    end

    describe "counts" do
      it "counts every enrolled participant" do
        expect(subject.total_count).to eq(3)
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
