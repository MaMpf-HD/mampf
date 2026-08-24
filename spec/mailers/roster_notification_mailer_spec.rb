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

    context "with a Lecture" do
      it "enqueues no email" do
        lecture = create(:lecture)

        expect do
          described_class.added(user, lecture)
        end.not_to have_enqueued_mail
      end
    end

    context "with an unsupported rosterable" do
      it "does not enqueue an email and logs instead" do
        unsupported = create(:registration_campaign)
        expect(Rails.logger).to receive(:error)
          .with(/Unsupported rosterable type: Registration::Campaign/)

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
        expect(Rails.logger).to receive(:error)
          .with(/Unsupported rosterable type: Registration::Campaign/)

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

    context "when the move is between tutorials" do
      let(:lecture) { create(:lecture) }
      let(:old_tutorial) { create(:tutorial, lecture: lecture, title: "Mo 10") }
      let(:new_tutorial) { create(:tutorial, lecture: lecture, title: "Di 14") }
      let!(:old_tutor) { create(:tutor_tutorial_join, tutorial: old_tutorial).tutor }
      let!(:new_tutor) { create(:tutor_tutorial_join, tutorial: new_tutorial).tutor }

      it "tells the tutor left behind that the work stays with them" do
        expect do
          described_class.moved(user, old_tutorial, new_tutorial)
        end.to have_enqueued_mail(described_class, :participant_left_group_email)
          .with(a_hash_including(params: a_hash_including(recipient: old_tutor)))
      end

      it "tells the receiving tutor that someone joins them" do
        expect do
          described_class.moved(user, old_tutorial, new_tutorial)
        end.to have_enqueued_mail(described_class, :participant_joined_group_email)
          .with(a_hash_including(params: a_hash_including(recipient: new_tutor)))
      end

      it "names the participant and where their earlier work stays" do
        email = described_class.with(
          participant: user,
          rosterable: old_tutorial,
          old_rosterable: old_tutorial,
          new_rosterable: new_tutorial,
          recipient: old_tutor
        ).participant_left_group_email

        delivered = deliver(email)

        expect(delivered.to).to eq([old_tutor.email])
        expect(delivered.subject).to include("Mo 10")
        expect(delivered_body(delivered)).to include("Alice")
        expect(delivered_body(delivered)).to include("Di 14")
      end
    end

    context "with an unsupported rosterable" do
      it "does not enqueue an email and logs instead" do
        old_unsupported = create(:registration_campaign)
        new_unsupported = create(:registration_campaign)
        expect(Rails.logger).to receive(:error)
          .with(/Unsupported rosterable type: Registration::Campaign/)

        expect do
          described_class.moved(user, old_unsupported, new_unsupported)
        end.not_to have_enqueued_mail
      end

      it "does not enqueue an email when only the target is unsupported" do
        old_tutorial = create(:tutorial)
        new_unsupported = create(:registration_campaign)
        expect(Rails.logger).to receive(:error)
          .with(/Unsupported rosterable type: Registration::Campaign/)

        expect do
          described_class.moved(user, old_tutorial, new_unsupported)
        end.not_to have_enqueued_mail
      end
    end
  end

  describe "#added_to_group_email" do
    let(:rosterable) { create(:tutorial, title: "Übung 3") }

    it "sends the correct email" do
      email = described_class.with(
        rosterable: rosterable,
        recipient: user
      ).added_to_group_email

      delivered = deliver(email)

      expect(delivered.to).to eq([user.email])
      expect(delivered[:from].value).to eq(NotificationMailer.sender(user.locale))
      expect(delivered.subject).to include("Übung 3")
      expect(delivered_body(delivered)).to include("hinzugefügt")
      expect(delivered_body(delivered)).to include("Alice")
    end
  end

  describe "#removed_from_group_email" do
    let(:rosterable) { create(:tutorial, title: "Übung 3") }

    it "sends the correct email" do
      email = described_class.with(
        rosterable: rosterable,
        recipient: user
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
        recipient: user
      ).removed_from_lecture_email

      delivered = deliver(email)

      # Lecture#title carries a translated type prefix, so it has to be read in
      # the locale the mail was rendered in.
      expected_title = I18n.with_locale(user.locale) { rosterable.title }
      expect(delivered.subject).to include(expected_title)
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
        recipient: user
      ).moved_between_groups_email

      delivered = deliver(email)

      expect(delivered.subject).to include("Übung 2")
      expect(delivered_body(delivered)).to include("Übung 1")
      expect(delivered_body(delivered)).to include("Übung 2")
      expect(delivered_body(delivered)).to include("Alice")
    end
  end

  describe "the plain text translations" do
    I18n.available_locales.each do |locale|
      it "carry no markup in #{locale}" do
        I18n.t("roster.mailer", locale: locale)
            .reject { |key, _| key.to_s.end_with?("_html") }
            .each do |key, value|
          expect(value).not_to match(%r{<[a-z/][^>]*>}i),
                               "roster.mailer.#{key} (#{locale}) contains markup: #{value.inspect}"
        end
      end
    end
  end

  describe "the text part of a delivered mail" do
    let(:rosterable) { create(:tutorial, title: "Übung 3") }

    def text_part_of(email)
      deliver(email).text_part.body.decoded
    end

    def expect_plain_text(body)
      expect(body).to include("Alice")
      expect(body).not_to match(%r{<[a-z/][^>]*>}i)
    end

    it "carries no markup when a user is added to a group" do
      expect_plain_text(text_part_of(described_class.with(
        rosterable: rosterable, recipient: user
      ).added_to_group_email))
    end

    it "carries no markup when a user is removed from a group" do
      expect_plain_text(text_part_of(described_class.with(
        rosterable: rosterable, recipient: user
      ).removed_from_group_email))
    end

    it "carries no markup when a user is removed from a lecture" do
      expect_plain_text(text_part_of(described_class.with(
        rosterable: create(:lecture), recipient: user
      ).removed_from_lecture_email))
    end

    it "carries no markup when a user is moved between groups" do
      expect_plain_text(text_part_of(described_class.with(
        old_rosterable: rosterable,
        new_rosterable: create(:tutorial, title: "Übung 7"),
        recipient: user
      ).moved_between_groups_email))
    end

    it "names both the tutor and the participant when someone leaves a tutorial" do
      tutor = create(:confirmed_user, name: "Bob", locale: "de")

      body = text_part_of(described_class.with(
        participant: user,
        rosterable: rosterable,
        old_rosterable: rosterable,
        new_rosterable: create(:tutorial, title: "Übung 7"),
        recipient: tutor
      ).participant_left_group_email)

      expect(body).to include("Bob")
      expect_plain_text(body)
    end

    it "spells the group link out as a plain URL" do
      talk = create(:talk)

      body = text_part_of(described_class.with(
        rosterable: talk, recipient: user
      ).added_to_group_email)

      expect(body).to match(%r{https?://\S*/talks/#{talk.id}})
    end
  end
end
