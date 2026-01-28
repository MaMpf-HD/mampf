require "rails_helper"

describe RosterNotificationMailer, "#added_to_group_email" do
  let(:user)       { create(:user, name: "Alice") }
  let(:rosterable) { create(:lecture, title: "Analysis I") }

  it "sends the correct email" do
    email = described_class.with(
      rosterable: rosterable,
      recipient: user,
      sender: "noreply@example.com"
    ).added_to_group_email

    expect { email.deliver_now }
      .to change { ActionMailer::Base.deliveries.count }.by(1)

    delivered = ActionMailer::Base.deliveries.last

    expect(delivered.to).to eq([user.email])
    expect(delivered.from).to eq(["noreply@example.com"])
    expect(delivered.subject).to include("Analysis I")
    expect(delivered.body.encoded).to include("hinzugefügt")
    expect(delivered.body.encoded).to include("Alice")
  end
end
describe RosterNotificationMailer, "#removed_from_group_email" do
  let(:user)       { create(:user, name: "Alice") }
  let(:rosterable) { create(:tutorial, title: "Übung 3") }

  it "sends the correct email" do
    email = described_class.with(
      rosterable: rosterable,
      recipient: user,
      sender: "noreply@example.com"
    ).removed_from_group_email

    expect { email.deliver_now }
      .to change { ActionMailer::Base.deliveries.count }.by(1)

    delivered = ActionMailer::Base.deliveries.last

    expect(delivered.subject).to include("Übung 3")
    expect(delivered.body.encoded).to include("entfernt")
  end
end
describe RosterNotificationMailer, "#moved_between_groups_email" do
  let(:user)          { create(:user, name: "Alice") }
  let(:old_group)     { create(:tutorial, title: "Übung 1") }
  let(:new_group)     { create(:tutorial, title: "Übung 2") }

  it "sends the correct email" do
    email = described_class.with(
      old_rosterable: old_group,
      new_rosterable: new_group,
      recipient: user,
      sender: "noreply@example.com"
    ).moved_between_groups_email

    expect { email.deliver_now }
      .to change { ActionMailer::Base.deliveries.count }.by(1)

    delivered = ActionMailer::Base.deliveries.last

    expect(delivered.subject).to include("Übung 2")
    expect(delivered.body.encoded).to include("Übung 1")
    expect(delivered.body.encoded).to include("Übung 2")
    expect(delivered.body.encoded).to include("Alice")
  end
end
