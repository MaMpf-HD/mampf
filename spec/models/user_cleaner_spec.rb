require "rails_helper"

RSpec.describe(UserCleaner, type: :model) do
  describe("#set/unset_deletion_date") do
    it "assigns a deletion date to inactive users" do
      inactive_user = FactoryBot.create(:user, last_sign_in_at: 7.months.ago)
      active_user = FactoryBot.create(:user, last_sign_in_at: 5.months.ago)

      UserCleaner.new.set_deletion_date_for_inactive_users
      inactive_user.reload
      active_user.reload

      expect(inactive_user.deletion_date).to eq(Date.current + 40.days)
      expect(active_user.deletion_date).to be_nil
    end

    it "unassigns a deletion date from recently active users" do
      deletion_date = Date.current + 5.days
      user_inactive = FactoryBot.create(:user, deletion_date: deletion_date,
                                               last_sign_in_at: 7.months.ago)
      user_inactive2 = FactoryBot.create(:user, deletion_date: deletion_date,
                                                last_sign_in_at: 6.months.ago - 1.day)
      user_active = FactoryBot.create(:user, deletion_date: deletion_date,
                                             last_sign_in_at: 2.days.ago)

      UserCleaner.new.unset_deletion_date_for_recently_active_users
      user_inactive.reload
      user_inactive2.reload
      user_active.reload

      expect(user_inactive.deletion_date).to eq(deletion_date)
      expect(user_inactive2.deletion_date).to eq(deletion_date)
      expect(user_active.deletion_date).to be_nil
    end
  end

  describe("#delete_users") do
    it "deletes users with a deletion date in the past or present" do
      user_past1 = FactoryBot.create(:user, deletion_date: Date.current - 1.day)
      user_past2 = FactoryBot.create(:user, deletion_date: Date.current - 1.year)
      user_present = FactoryBot.create(:user, deletion_date: Date.current)

      UserCleaner.new.delete_users_according_to_deletion_date!

      expect(User.where(id: user_past1.id)).not_to exist
      expect(User.where(id: user_past2.id)).not_to exist
      expect(User.where(id: user_present.id)).not_to exist
    end

    it "does not delete users with a deletion date in the future" do
      user_future1 = FactoryBot.create(:user, deletion_date: Date.current + 1.day)
      user_future2 = FactoryBot.create(:user, deletion_date: Date.current + 1.year)

      UserCleaner.new.delete_users_according_to_deletion_date!

      expect(User.where(id: user_future1.id)).to exist
      expect(User.where(id: user_future2.id)).to exist
    end

    it "does not delete users without a deletion date" do
      user = FactoryBot.create(:user, deletion_date: nil)
      UserCleaner.new.delete_users_according_to_deletion_date!
      expect(User.where(id: user.id)).to exist
    end

    it "deletes only generic users" do
      deletion_date = Date.current - 1.day
      user_generic = FactoryBot.create(:user, deletion_date: deletion_date)

      # Non-generic users are either admins, teachers or editors
      user_admin = FactoryBot.create(:user, deletion_date: deletion_date, admin: true)
      user_teacher = FactoryBot.create(:user, deletion_date: deletion_date)
      FactoryBot.create(:lecture, teacher: user_teacher)
      user_editor = FactoryBot.create(:user, deletion_date: deletion_date)
      FactoryBot.create(:lecture, editors: [user_editor])

      UserCleaner.new.delete_users_according_to_deletion_date!

      expect(User.where(id: user_generic.id)).not_to exist
      expect(User.where(id: user_admin.id)).to exist
      expect(User.where(id: user_teacher.id)).to exist
      expect(User.where(id: user_editor.id)).to exist
    end
  end

  describe("#warning_mail") do
    context "when setting a deletion date" do
      it "enqueues a deletion warning mail (40 days)" do
        FactoryBot.create(:user, last_sign_in_at: 7.months.ago)

        expect do
          UserCleaner.new.set_deletion_date_for_inactive_users
        end.to have_enqueued_mail(UserCleanerMailer, :pending_deletion_email)
          .with(a_hash_including(args: [40]))
      end
    end

    context "when a deletion date is assigned" do
      def test_enqueues_additional_deletion_warning_mails(num_days)
        FactoryBot.create(:user, deletion_date: Date.current + num_days.days)

        expect do
          UserCleaner.new.send_additional_warning_mails
        end.to have_enqueued_mail(UserCleanerMailer, :pending_deletion_email)
          .with(a_hash_including(args: [num_days]))
      end

      it "enqueues additional deletion warning mails" do
        test_enqueues_additional_deletion_warning_mails(14)
        test_enqueues_additional_deletion_warning_mails(7)
        test_enqueues_additional_deletion_warning_mails(2)
      end

      it "does not enqueue an additional deletion warning mail for 40 days" do
        FactoryBot.create(:user, deletion_date: Date.current + 40.days)

        expect do
          UserCleaner.new.send_additional_warning_mails
        end.not_to have_enqueued_mail(UserCleanerMailer, :pending_deletion_email)
      end
    end
  end

  describe("#pending_deletion_mail") do
    let(:user_de) { FactoryBot.create(:user, locale: "de") }
    let(:user_en) { FactoryBot.create(:user, locale: "en") }

    def test_subject_line(num_days)
      user = FactoryBot.create(:user)
      mailer = UserCleanerMailer.with(user: user).pending_deletion_email(num_days)
      expect(mailer.subject).to include(num_days.to_s)
    end

    it "has mail subject containing the number of days until deletion" do
      test_subject_line(40)
      test_subject_line(14)
      test_subject_line(7)
      test_subject_line(2)
    end

    it "has mail subject localized to the user's locale" do
      mailer = UserCleanerMailer.with(user: user_de).pending_deletion_email(40)
      expect(mailer.subject).to include("Tage")
      expect(mailer.subject).not_to include("days")

      mailer = UserCleanerMailer.with(user: user_en).pending_deletion_email(40)
      expect(mailer.subject).to include("days")
      expect(mailer.subject).not_to include("Tage")
    end

    it "has mail body localized to the user's locale" do
      mailer = UserCleanerMailer.with(user: user_de).pending_deletion_email(40)
      expect(mailer.body.encoded).to include("verloren")
      expect(mailer.body.encoded).not_to include("lost")

      mailer = UserCleanerMailer.with(user: user_en).pending_deletion_email(40)
      expect(mailer.body.encoded).to include("lost")
      expect(mailer.body.encoded).not_to include("verloren")
    end
  end
end
