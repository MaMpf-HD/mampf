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

    it "generates correct paths" do
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

    it "generates correct paths" do
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
  end
end
