require "rails_helper"

RSpec.describe(RosterDetailComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:user) { create(:user, name: "Alice") }
  let(:other_user) { create(:user, name: "Bob") }

  context "with a Tutorial" do
    let(:tutorial) { create(:tutorial, lecture: lecture, manual_roster_mode: true) }
    let!(:other_tutorial) do
      create(:tutorial, lecture: lecture, title: "Other Tutorial", manual_roster_mode: true)
    end
    let(:component) { described_class.new(rosterable: tutorial) }

    before do
      tutorial.members << user
    end

    it "renders the component" do
      render_inline(component)
      expect(rendered_content).to include(tutorial.title)
      expect(rendered_content).to include("Alice")
    end

    it "lists students" do
      expect(component.students).to include(user)
      expect(component.students).not_to include(other_user)
    end

    it "lists available groups excluding self" do
      render_inline(component)
      expect(component.available_groups).to include(other_tutorial)
      expect(component.available_groups).not_to include(tutorial)
    end

    it "includes cohorts in available groups" do
      cohort = create(:cohort, context: lecture, manual_roster_mode: true)
      expect(component.available_groups).to include(cohort)
    end

    describe "path generation" do
      it "generates correct paths without group_type" do
        render_inline(component)
        expect(component.add_member_path)
          .to eq(Rails.application.routes.url_helpers.add_member_tutorial_path(tutorial))
        expect(component.remove_member_path(user))
          .to eq(Rails.application.routes.url_helpers.remove_member_tutorial_path(
                   tutorial, user
                 ))
        expect(component.move_member_path(user))
          .to eq(Rails.application.routes.url_helpers.move_member_tutorial_path(
                   tutorial, user
                 ))
      end

      context "with group_type" do
        let(:component) { described_class.new(rosterable: tutorial, group_type: :tutorials) }

        it "includes group_type in paths" do
          render_inline(component)
          expect(component.add_member_path)
            .to eq(Rails.application.routes.url_helpers
            .add_member_tutorial_path(tutorial,
                                      group_type: :tutorials))
          expect(component.remove_member_path(user))
            .to eq(Rails.application.routes.url_helpers.remove_member_tutorial_path(
                     tutorial, user, group_type: :tutorials
                   ))
          expect(component.move_member_path(user))
            .to eq(Rails.application.routes.url_helpers.move_member_tutorial_path(
                     tutorial, user, group_type: :tutorials
                   ))
        end
      end
    end

    describe "#overbooked?" do
      it "returns false if group has no capacity" do
        tutorial.update(capacity: nil)
        expect(component.overbooked?).to be(false)
      end

      it "returns false if group is not full" do
        tutorial.update(capacity: 10)
        expect(component.overbooked?).to be(false)
      end

      it "returns true if group is full" do
        tutorial.update(capacity: 1)
        expect(component.overbooked?).to be(true)
      end

      it "returns true if group is over capacity" do
        tutorial.update(capacity: 0)
        expect(component.overbooked?).to be(true)
      end

      it "checks other group if provided" do
        other_tutorial.update(capacity: 0)
        expect(component.overbooked?(other_tutorial)).to be(true)
      end
    end

    describe "#transfer_targets" do
      it "returns a list of targets grouped by type" do
        other_tutorial.update(capacity: 0)
        render_inline(component)
        targets = component.transfer_targets

        tutorial_group = targets.find { |t| t[:type] == :tutorials }
        expect(tutorial_group).to be_present

        item = tutorial_group[:items].first
        expect(item).to include(
          group: other_tutorial,
          overbooked: true,
          id: other_tutorial.id
        )
        expect(item[:title]).to include(other_tutorial.title)
      end
    end
  end

  context "with a Talk" do
    let(:talk) { create(:talk, lecture: lecture, manual_roster_mode: true) }
    let!(:other_talk) do
      create(:talk, lecture: lecture, title: "Other Talk", manual_roster_mode: true)
    end
    let(:component) { described_class.new(rosterable: talk) }

    before do
      talk.speakers << user
    end

    it "renders the component" do
      render_inline(component)
      expect(rendered_content).to include(talk.title)
      expect(rendered_content).to include("Alice")
    end

    it "lists students (speakers)" do
      expect(component.students).to include(user)
    end

    it "lists available groups excluding self" do
      render_inline(component)
      expect(component.available_groups).to include(other_talk)
      expect(component.available_groups).not_to include(talk)
    end

    describe "path generation" do
      it "generates correct paths without group_type" do
        render_inline(component)
        expect(component.add_member_path)
          .to eq(Rails.application.routes.url_helpers.add_member_talk_path(talk))
        expect(component.remove_member_path(user))
          .to eq(Rails.application.routes.url_helpers.remove_member_talk_path(
                   talk, user
                 ))
        expect(component.move_member_path(user))
          .to eq(Rails.application.routes.url_helpers.move_member_talk_path(
                   talk, user
                 ))
      end

      context "with group_type" do
        let(:component) { described_class.new(rosterable: talk, group_type: :talks) }

        it "includes group_type in paths" do
          render_inline(component)
          expect(component.add_member_path)
            .to eq(Rails.application.routes.url_helpers.add_member_talk_path(talk,
                                                                             group_type: :talks))
          expect(component.remove_member_path(user))
            .to eq(Rails.application.routes.url_helpers.remove_member_talk_path(
                     talk, user, group_type: :talks
                   ))
          expect(component.move_member_path(user))
            .to eq(Rails.application.routes.url_helpers.move_member_talk_path(
                     talk, user, group_type: :talks
                   ))
        end
      end
    end
  end
end
