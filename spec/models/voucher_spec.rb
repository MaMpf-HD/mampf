require "rails_helper"

RSpec.describe(Voucher, type: :model) do
  let(:lecture) { FactoryBot.create(:lecture) }
  let(:seminar) { FactoryBot.create(:lecture, :is_seminar) }

  describe "callbacks" do
    it "generates a secure hash before creating" do
      voucher = FactoryBot.build(:voucher)
      expect(voucher.secure_hash).to be_nil
      voucher.save
      expect(voucher.secure_hash).not_to be_nil
    end

    it "adds an expiration datetime before creating" do
      voucher = FactoryBot.build(:voucher)
      expect(voucher.expires_at).to be_nil
      voucher.save
      expect(voucher.expires_at).not_to be_nil
    end

    describe "#add_expiration_datetime" do
      def expiration_days(role)
        case role
        when :speaker
          Voucher::SPEAKER_EXPIRATION_DAYS
        when :tutor
          Voucher::TUTOR_EXPIRATION_DAYS
        else
          Voucher::DEFAULT_EXPIRATION_DAYS
        end
      end

      it "sets the expiration date correctly based on the role" do
        Voucher::ROLE_HASH.each_key do |role|
          voucher = build(:voucher, lecture: lecture, role: role)
          voucher.save
          expect(voucher.expires_at).to eq(voucher.created_at + expiration_days(role).days)
        end
      end
    end

    describe "#ensure_no_other_active_voucher" do
      it "rolls back if there is another active voucher with the same role for the lecture" do
        FactoryBot.create(:voucher, :tutor, lecture: lecture)
        new_voucher = build(:voucher, :tutor, lecture: lecture)

        expect(new_voucher.save).to be_falsey
        expect(new_voucher.errors[:role]).to(
          include(I18n.t("activerecord.errors.models.voucher." \
                         "attributes.role.only_one_active"))
        )
      end
    end

    describe "#ensure_speaker_vouchers_only_for_seminars" do
      context "when the lecture is a seminar" do
        let(:voucher) { build(:voucher, :speaker, lecture: seminar) }

        it "does not add an error" do
          expect(voucher).to be_valid
          expect(voucher.save).to be_truthy
          expect(voucher.errors[:role]).to be_empty
        end
      end

      context "when the lecture is not a seminar" do
        let(:voucher) { build(:voucher, :speaker, lecture: lecture) }

        it "rolls back and adds an error" do
          expect(voucher.save).to be_falsey
          expect(voucher.errors[:role]).to(
            include(I18n.t("activerecord.errors.models.voucher.attributes." \
                           "role.speaker_vouchers_only_for_seminars"))
          )
        end
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      it "includes vouchers that are not expired and not invalidated" do
        active_voucher = FactoryBot.create(:voucher)
        expect(Voucher.active).to include(active_voucher)
      end

      it "excludes vouchers that are expired" do
        expired_voucher = FactoryBot.create(:voucher, :expired)
        expect(Voucher.active).not_to include(expired_voucher)
      end

      it "excludes vouchers that are invalidated" do
        invalidated_voucher = FactoryBot.create(:voucher, :invalidated)
        expect(Voucher.active).not_to include(invalidated_voucher)
      end

      it "excludes vouchers that are both expired and invalidated" do
        voucher = FactoryBot.create(:voucher, :expired, :invalidated)
        expect(Voucher.active).not_to include(voucher)
      end
    end
  end

  describe "class methods" do
    describe ".roles_for_lecture" do
      context "when lecture is a seminar" do
        context "when roster_maintenance is enabled" do
          before { Flipper.enable(:roster_maintenance) }

          it "returns all roles except :tutor" do
            expect(Voucher.roles_for_lecture(seminar)).to eq(Voucher::ROLE_HASH.keys - [:tutor])
          end
        end

        context "when roster_maintenance is disabled" do
          before { Flipper.disable(:roster_maintenance) }

          it "returns all roles" do
            expect(Voucher.roles_for_lecture(seminar)).to eq(Voucher::ROLE_HASH.keys)
          end
        end
      end

      context "when lecture is not a seminar" do
        it "returns all roles except :speaker" do
          expect(Voucher.roles_for_lecture(lecture)).to eq(Voucher::ROLE_HASH.keys - [:speaker])
        end
      end
    end
  end

  describe "instance methods" do
    describe "#invalidate!" do
      it "sets the invalidated_at attribute to the current time" do
        voucher = FactoryBot.create(:voucher)
        expect(voucher.invalidated_at).to be_nil
        frozen_time = Time.zone.now.change(nsec: 0)
        Timecop.freeze(frozen_time) do
          voucher.invalidate!
          expect(voucher.invalidated_at).to eq(frozen_time)
        end
      end
    end
  end
end
