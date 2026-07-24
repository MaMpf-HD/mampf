require "rails_helper"

describe RosterNotificationMailer do
  let(:user) { create(:user, name: "Alice", locale: "de") }

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

  describe ".added" do
    context "with a supported rosterable" do
      it "enqueues an email for a Lecture" do
        lecture = create(:lecture)

        expect do
          described_class.added(user, lecture)
        end.to have_enqueued_mail(described_class, :added_to_lecture_email)
      end

      it "enqueues an email for a Tutorial" do
        tutorial = create(:tutorial)

        expect do
          described_class.added(user, tutorial)
        end.to have_enqueued_mail(described_class, :added_to_group_email)
      end

      it "enqueues an email for a Cohort" do
        cohort = create(:cohort)

        expect do
          described_class.added(user, cohort)
        end.to have_enqueued_mail(described_class, :added_to_group_email)
      end

      it "enqueues an email for a Talk" do
        talk = create(:talk)

        expect do
          described_class.added(user, talk)
        end.to have_enqueued_mail(described_class, :added_to_group_email)
      end
    end

    context "with an unsupported rosterable" do
      it "does not enqueue an email and logs instead" do
        unsupported = create(:registration_campaign)
        expect(described_class).to receive(:log_unsupported).with(unsupported).and_call_original

        expect do
          described_class.added(user, unsupported)
        end.not_to have_enqueued_mail
      end
    end
  end

  describe ".removed" do
    context "with a supported rosterable" do
      it "enqueues an email for a Lecture" do
        lecture = create(:lecture)

        expect do
          described_class.removed(user, lecture)
        end.to have_enqueued_mail(described_class, :removed_from_lecture_email)
      end

      it "enqueues an email for a Tutorial" do
        tutorial = create(:tutorial)

        expect do
          described_class.removed(user, tutorial)
        end.to have_enqueued_mail(described_class, :removed_from_group_email)
      end

      it "enqueues an email for a Cohort" do
        cohort = create(:cohort)

        expect do
          described_class.removed(user, cohort)
        end.to have_enqueued_mail(described_class, :removed_from_group_email)
      end

      it "enqueues an email for a Talk" do
        talk = create(:talk)

        expect do
          described_class.removed(user, talk)
        end.to have_enqueued_mail(described_class, :removed_from_group_email)
      end
    end

    context "with an unsupported rosterable" do
      it "does not enqueue an email and logs instead" do
        unsupported = create(:registration_campaign)
        expect(described_class).to receive(:log_unsupported).with(unsupported).and_call_original
        expect do
          described_class.removed(user, unsupported)
        end.not_to have_enqueued_mail
      end
    end
  end

  describe ".moved" do
    context "with a supported rosterable" do
      it "enqueues an email for a Lecture" do
        old_lecture = create(:lecture)
        new_lecture = create(:lecture)

        expect do
          described_class.moved(user, old_lecture, new_lecture)
        end.to have_enqueued_mail(described_class, :moved_between_groups_email)
      end

      it "enqueues an email for a Tutorial" do
        old_tutorial = create(:tutorial)
        new_tutorial = create(:tutorial)

        expect do
          described_class.moved(user, old_tutorial, new_tutorial)
        end.to have_enqueued_mail(described_class, :moved_between_groups_email)
      end

      it "enqueues an email for a Cohort" do
        old_cohort = create(:cohort)
        new_cohort = create(:cohort)

        expect do
          described_class.moved(user, old_cohort, new_cohort)
        end.to have_enqueued_mail(described_class, :moved_between_groups_email)
      end

      it "enqueues an email for a Talk" do
        old_talk = create(:talk)
        new_talk = create(:talk)

        expect do
          described_class.moved(user, old_talk, new_talk)
        end.to have_enqueued_mail(described_class, :moved_between_groups_email)
      end
    end

    context "with an unsupported rosterable" do
      it "does not enqueue an email and logs instead" do
        old_unsupported = create(:registration_campaign)
        new_unsupported = create(:registration_campaign)
        expect(described_class).to receive(:log_unsupported).with(old_unsupported).and_call_original
        expect do
          described_class.moved(user, old_unsupported, new_unsupported)
        end.not_to have_enqueued_mail
      end
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
