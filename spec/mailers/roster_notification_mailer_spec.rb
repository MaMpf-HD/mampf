require "rails_helper"

describe RosterNotificationMailer do
  let(:user) { create(:user, name: "Alice") }

  def deliver(email)
    expect { email.deliver_now }
      .to change { ActionMailer::Base.deliveries.count }.by(1)

    ActionMailer::Base.deliveries.last
  end

  def delivered_body(mail)
    if mail.multipart?
      (mail.html_part || mail.text_part).body.decoded
    else
      mail.body.decoded
    end
  end

  describe "#added_to_group_email" do
    let(:rosterable) { create(:tutorial, title: "Übung 3") }

    it "sends the correct email" do
      email = described_class.with(
        rosterable: rosterable,
        recipient: user,
        sender: "noreply@example.com"
      ).added_to_group_email

      delivered = deliver(email)

      expect(delivered.to).to eq([user.email])
      expect(delivered.from).to eq(["noreply@example.com"])
      expect(delivered.subject).to include("Übung 3")
      expect(delivered_body(delivered)).to include("hinzugefügt")
      expect(delivered_body(delivered)).to include("Alice")
    end
  end

  describe "#added_to_lecture_email" do
    let(:rosterable) { create(:lecture) }

    it "sends the correct email" do
      email = described_class.with(
        rosterable: rosterable,
        recipient: user,
        sender: "noreply@example.com"
      ).added_to_lecture_email

      delivered = deliver(email)

      expect(delivered.subject).to include(rosterable.title)
      expect(delivered_body(delivered)).to include("hinzugefügt")
    end
  end

  describe "#removed_from_group_email" do
    let(:rosterable) { create(:tutorial, title: "Übung 3") }

    it "sends the correct email" do
      email = described_class.with(
        rosterable: rosterable,
        recipient: user,
        sender: "noreply@example.com"
      ).removed_from_group_email

      delivered = deliver(email)

      expect(delivered.subject).to include("Übung 3")
      expect(delivered_body(delivered)).to include("entfernt")
    end
  end

  describe "#removed_from_lecture_email" do
    let(:rosterable) { create(:lecture) }

    it "sends the correct email" do
      email = described_class.with(
        rosterable: rosterable,
        recipient: user,
        sender: "noreply@example.com"
      ).removed_from_lecture_email

      delivered = deliver(email)

      expect(delivered.subject).to include(rosterable.title)
      expect(delivered_body(delivered)).to include("entfernt")
    end
  end

  describe "#moved_between_groups_email" do
    let(:old_group) { create(:tutorial, title: "Übung 1") }
    let(:new_group) { create(:tutorial, title: "Übung 2") }

    it "sends the correct email" do
      email = described_class.with(
        old_rosterable: old_group,
        new_rosterable: new_group,
        recipient: user,
        sender: "noreply@example.com"
      ).moved_between_groups_email

      delivered = deliver(email)

      expect(delivered.subject).to include("Übung 2")
      expect(delivered_body(delivered)).to include("Übung 1")
      expect(delivered_body(delivered)).to include("Übung 2")
      expect(delivered_body(delivered)).to include("Alice")
    end
  end
end
