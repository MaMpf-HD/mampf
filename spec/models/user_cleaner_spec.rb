require "rails_helper"

RSpec.describe(UserCleaner, type: :model) do
  # Non-generic users are either admins, teachers or editors
  let(:user_admin) do
    return FactoryBot.create(:confirmed_user, deletion_date: Date.current - 1.day, admin: true)
  end

  let(:user_teacher) do
    user_teacher = FactoryBot.create(:confirmed_user, deletion_date: Date.current - 1.day)
    FactoryBot.create(:lecture, teacher: user_teacher)
    return user_teacher
  end

  let(:user_editor) do
    user_editor = FactoryBot.create(:confirmed_user, deletion_date: Date.current - 1.day)
    FactoryBot.create(:lecture, editors: [user_editor])
    return user_editor
  end

  before(:each) do
    UserCleaner::INACTIVE_USER_THRESHOLD = 6.months
  end

  describe("#inactive_users") do
    context "when user is confirmed" do
      it "counts users without current_sign_in_at date as inactive" do
        # but only if also the confirmation date is older than the threshold
        FactoryBot.create(:confirmed_user, :with_confirmation_sent_date,
                          confirmation_sent_date: 5.months.ago, current_sign_in_at: nil)
        FactoryBot.create(:confirmed_user, :with_confirmation_sent_date,
                          confirmation_sent_date: 7.months.ago, current_sign_in_at: nil)
        expect(UserCleaner.new.inactive_users.count).to eq(1)
      end

      it("counts users with current_sign_in_at date older than threshold as inactive") do
        FactoryBot.create(:confirmed_user, current_sign_in_at: 7.months.ago)
        expect(UserCleaner.new.inactive_users.count).to eq(1)
      end

      it "does not count users with current_sign_in_at date younger than threshold as inactive" do
        FactoryBot.create(:confirmed_user, current_sign_in_at: 5.months.ago)
        expect(UserCleaner.new.inactive_users.count).to eq(0)
      end
    end

    context "when user is not confirmed yet" do
      def test_non_confirmed_user(confirmation_sent_date, expected_inactive_users_count)
        user = FactoryBot.create(:user, :with_confirmation_sent_date,
                                 confirmation_sent_date: confirmation_sent_date,
                                 current_sign_in_at: nil)
        FactoryBot.create(:user, :with_confirmation_sent_date,
                          confirmation_sent_date: confirmation_sent_date,
                          current_sign_in_at: 5.months.ago)
        FactoryBot.create(:user, :with_confirmation_sent_date,
                          confirmation_sent_date: confirmation_sent_date,
                          current_sign_in_at: 7.months.ago)

        expect(user.confirmed_at).to be_nil
        expect(user.confirmation_sent_at).to eq(confirmation_sent_date)

        expect(UserCleaner.new.inactive_users.count).to eq(expected_inactive_users_count)
      end

      context "when registration was recently" do
        it "does not count user as inactive regardless of value of last_sign_in_date" do
          test_non_confirmed_user(5.days.ago, 0)
        end
      end

      context "when registration was long ago" do
        it "counts users as inactive regardless of value of last_sign_in_date" do
          test_non_confirmed_user(7.months.ago, 3)
        end
      end
    end
  end

  describe("#set/unset_deletion_date") do
    context "when deletion date is nil" do
      it "assigns a deletion date to inactive users" do
        inactive_user = FactoryBot.create(:confirmed_user, current_sign_in_at: 7.months.ago)
        inactive_user2 = FactoryBot.create(:user, :with_confirmation_sent_date,
                                           confirmation_sent_date: 7.months.ago)
        active_user = FactoryBot.create(:confirmed_user, current_sign_in_at: 5.months.ago)

        UserCleaner.new.set_deletion_date_for_inactive_users
        inactive_user.reload
        inactive_user2.reload
        active_user.reload

        expect(inactive_user.deletion_date).to eq(Date.current + 40.days)
        expect(inactive_user2.deletion_date).to eq(Date.current + 40.days)
        expect(active_user.deletion_date).to be_nil
      end

      it "only assigns a deletion date to a limited number of users" do
        max_deletions = 3
        UserCleaner::MAX_DELETIONS_PER_RUN = max_deletions

        FactoryBot.create_list(:confirmed_user, max_deletions + 2,
                               current_sign_in_at: 7.months.ago)

        UserCleaner.new.set_deletion_date_for_inactive_users

        users_flagged = User.where(deletion_date: Date.current + 40.days)
        expect(users_flagged.count).to eq(max_deletions)
      end

      it "assigns a deletion date even if validations fail" do
        user = FactoryBot.create(:confirmed_user, current_sign_in_at: 7.months.ago)
        user.name = ""
        user.save(validate: false)
        user.reload

        user_invalid = User.find(user.id)
        expect(user_invalid).not_to be_valid

        UserCleaner.new.set_deletion_date_for_inactive_users
        user_invalid.reload

        expect(user_invalid.deletion_date).to eq(Date.current + 40.days)
      end
    end

    context "when a deletion date is assigned" do
      it "does not overwrite the deletion date" do
        user = FactoryBot.create(:confirmed_user, current_sign_in_at: 7.months.ago,
                                                  deletion_date: Date.current + 42.days)
        user2 = FactoryBot.create(:user, :with_confirmation_sent_date,
                                  confirmation_sent_date: 7.months.ago,
                                  deletion_date: Date.current + 44.days)

        UserCleaner.new.set_deletion_date_for_inactive_users
        user.reload
        user2.reload

        expect(user.deletion_date).to eq(Date.current + 42.days)
        expect(user2.deletion_date).to eq(Date.current + 44.days)
      end
    end

    it "unassigns a deletion date from recently active users" do
      deletion_date = Date.current + 5.days
      user_inactive = FactoryBot.create(:confirmed_user, deletion_date: deletion_date,
                                                         current_sign_in_at: 7.months.ago)
      user_inactive2 = FactoryBot.create(:confirmed_user, deletion_date: deletion_date,
                                                          current_sign_in_at: 6.months.ago - 1.day)
      user_active = FactoryBot.create(:confirmed_user, deletion_date: deletion_date,
                                                       current_sign_in_at: 2.days.ago)

      UserCleaner.new.unset_deletion_date_for_recently_active_users
      user_inactive.reload
      user_inactive2.reload
      user_active.reload

      expect(user_inactive.deletion_date).to eq(deletion_date)
      expect(user_inactive2.deletion_date).to eq(deletion_date)
      expect(user_active.deletion_date).to be_nil
    end

    it "unassigns a deletion from a recently active user even if validations fail" do
      user = FactoryBot.create(:confirmed_user, current_sign_in_at: 2.days.ago,
                                                deletion_date: Date.current + 5.days)
      user.name = ""
      user.save(validate: false)
      user.reload

      user_invalid = User.find(user.id)
      expect(user_invalid).not_to be_valid

      UserCleaner.new.unset_deletion_date_for_recently_active_users
      user_invalid.reload

      expect(user_invalid.deletion_date).to be_nil
    end
  end

  describe("#delete_users") do
    it "deletes users with a deletion date in the past or present" do
      user_past1 = FactoryBot.create(:confirmed_user, deletion_date: Date.current - 1.day)
      user_past2 = FactoryBot.create(:confirmed_user, deletion_date: Date.current - 1.year)
      user_present = FactoryBot.create(:confirmed_user, deletion_date: Date.current)

      UserCleaner.new.delete_users_according_to_deletion_date!

      expect(User.where(id: user_past1.id)).not_to exist
      expect(User.where(id: user_past2.id)).not_to exist
      expect(User.where(id: user_present.id)).not_to exist
    end

    it "does not delete users with a deletion date in the future" do
      user_future1 = FactoryBot.create(:confirmed_user, deletion_date: Date.current + 1.day)
      user_future2 = FactoryBot.create(:confirmed_user, deletion_date: Date.current + 1.year)

      UserCleaner.new.delete_users_according_to_deletion_date!

      expect(User.where(id: user_future1.id)).to exist
      expect(User.where(id: user_future2.id)).to exist
    end

    it "does not delete users without a deletion date" do
      user = FactoryBot.create(:confirmed_user, deletion_date: nil)
      UserCleaner.new.delete_users_according_to_deletion_date!
      expect(User.where(id: user.id)).to exist
    end

    it "deletes only generic users" do
      user_generic = FactoryBot.create(:confirmed_user, deletion_date: Date.current - 1.day)
      user_admin
      user_teacher
      user_editor

      UserCleaner.new.delete_users_according_to_deletion_date!

      expect(User.where(id: user_generic.id)).not_to exist
      expect(User.where(id: user_admin.id)).to exist
      expect(User.where(id: user_teacher.id)).to exist
      expect(User.where(id: user_editor.id)).to exist
    end
  end

  describe("mails") do
    context "when setting a deletion date" do
      it "enqueues a deletion warning mail (40 days)" do
        user = FactoryBot.create(:confirmed_user, current_sign_in_at: 7.months.ago)

        expect do
          UserCleaner.new.set_deletion_date_for_inactive_users
        end.to(have_enqueued_mail(UserCleanerMailer, :pending_deletion_email)
          .with(user.email, user.locale, 40))
      end

      it "does not enqueue a deletion warning mail (40 days) for non-generic users" do
        user_admin
        user_teacher
        user_editor

        expect do
          UserCleaner.new.set_deletion_date_for_inactive_users
        end.not_to have_enqueued_mail(UserCleanerMailer, :pending_deletion_email)
      end
    end

    context "when a deletion date is assigned" do
      def test_enqueues_additional_deletion_warning_mails(num_days)
        user = FactoryBot.create(:confirmed_user, deletion_date: Date.current + num_days.days)

        expect do
          UserCleaner.new.send_additional_warning_mails
        end.to(have_enqueued_mail(UserCleanerMailer, :pending_deletion_email)
        .with(user.email, user.locale, num_days))
      end

      it "enqueues additional deletion warning mails" do
        test_enqueues_additional_deletion_warning_mails(14)
        test_enqueues_additional_deletion_warning_mails(7)
        test_enqueues_additional_deletion_warning_mails(2)
      end

      it "does not enqueue an additional deletion warning mail for 40 days" do
        FactoryBot.create(:confirmed_user, deletion_date: Date.current + 40.days)

        expect do
          UserCleaner.new.send_additional_warning_mails
        end.not_to have_enqueued_mail(UserCleanerMailer, :pending_deletion_email)
      end

      it "does not enqueue additional deletion warning mails for non-generic users" do
        user_admin.update(deletion_date: Date.current + 14.days)
        user_teacher.update(deletion_date: Date.current + 7.days)
        user_editor.update(deletion_date: Date.current + 2.days)

        expect do
          UserCleaner.new.send_additional_warning_mails
        end.not_to have_enqueued_mail(UserCleanerMailer, :pending_deletion_email)
      end
    end

    context "when a user is finally deleted" do
      it "enqueues a deletion mail" do
        user = FactoryBot.create(:confirmed_user, deletion_date: Date.current - 1.day)

        expect do
          UserCleaner.new.delete_users_according_to_deletion_date!
        end.to(have_enqueued_mail(UserCleanerMailer, :deletion_email)
          .with(user.email, user.locale))
      end
    end
  end

  describe("#pending_deletion_mail") do
    let(:user_de) { FactoryBot.create(:confirmed_user, locale: "de") }
    let(:user_en) { FactoryBot.create(:confirmed_user, locale: "en") }

    def test_subject_line(num_days)
      user = FactoryBot.create(:confirmed_user)
      mailer = UserCleanerMailer
               .pending_deletion_email(user.email, user.locale, num_days)
      expect(mailer.subject).to include(num_days.to_s)
    end

    it "has mail subject containing the number of days until deletion" do
      test_subject_line(40)
      test_subject_line(14)
      test_subject_line(7)
      test_subject_line(2)
    end

    it "has mail subject localized to the user's locale" do
      mailer = UserCleanerMailer
               .pending_deletion_email(user_de.email, user_de.locale, 40)
      expect(mailer.subject).to include("Tage")
      expect(mailer.subject).not_to include("days")

      mailer = UserCleanerMailer
               .pending_deletion_email(user_en.email, user_en.locale, 40)
      expect(mailer.subject).to include("days")
      expect(mailer.subject).not_to include("Tage")
    end

    it "has mail body localized to the user's locale" do
      expected_de = "verloren"
      expected_en = "lost"

      mailer = UserCleanerMailer
               .pending_deletion_email(user_de.email, user_de.locale, 40)
      expect(mailer.html_part.body).to include(expected_de)
      expect(mailer.html_part.body).not_to include(expected_en)

      mailer = UserCleanerMailer
               .pending_deletion_email(user_en.email, user_en.locale, 40)
      expect(mailer.html_part.body).to include(expected_en)
      expect(mailer.html_part.body).not_to include(expected_de)
    end
  end

  describe("#deletion_mail") do
    let(:user_de) { FactoryBot.create(:confirmed_user, locale: "de") }
    let(:user_en) { FactoryBot.create(:confirmed_user, locale: "en") }

    it "has mail subject localized to the user's locale" do
      mailer = UserCleanerMailer.deletion_email(user_de.email, user_de.locale)
      expect(mailer.subject).to include("gelöscht")
      expect(mailer.subject).not_to include("deleted")

      mailer = UserCleanerMailer.deletion_email(user_en.email, user_en.locale)
      expect(mailer.subject).to include("deleted")
      expect(mailer.subject).not_to include("gelöscht")
    end

    it "has mail body localized to the user's locale" do
      expected_de = "vollständig gelöscht"
      expected_en = "deleted entirely"

      mailer = UserCleanerMailer.deletion_email(user_de.email, user_de.locale)

      expect(mailer.html_part.body).to include(expected_de)
      expect(mailer.html_part.body).not_to include(expected_en)

      mailer = UserCleanerMailer.deletion_email(user_en.email, user_en.locale)

      expect(mailer.html_part.body).to include(expected_en)
      expect(mailer.html_part.body).not_to include(expected_de)
    end
  end
end
