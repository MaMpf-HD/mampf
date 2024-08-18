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
      let(:voucher) { build(:voucher, sort: sort, created_at: Time.zone.now) }

      context "when the voucher is for a speaker" do
        let(:sort) { :speaker }

        it "sets the expiration date to SPEAKER_EXPIRATION_DAYS from created_at" do
          voucher.save
          expect(voucher.expires_at).to(
            eq(voucher.created_at + Voucher::SPEAKER_EXPIRATION_DAYS.days)
          )
        end
      end

      context "when the voucher is for a tutor" do
        let(:sort) { :tutor }

        it "sets the expiration date to TUTOR_EXPIRATION_DAYS from created_at" do
          voucher.save
          expect(voucher.expires_at).to(
            eq(voucher.created_at + Voucher::TUTOR_EXPIRATION_DAYS.days)
          )
        end
      end

      context "when the voucher is for another sort" do
        let(:sort) { :teacher }

        it "sets the expiration date to DEFAULT_EXPIRATION_DAYS from created_at" do
          voucher.save
          expect(voucher.expires_at).to(
            eq(voucher.created_at + Voucher::DEFAULT_EXPIRATION_DAYS.days)
          )
        end
      end
    end

    describe "#ensure_no_other_active_voucher" do
      it "rolls back if there is another active voucher with the same sort for the lecture" do
        FactoryBot.create(:voucher, :tutor, lecture: lecture)
        new_voucher = build(:voucher, :tutor, lecture: lecture)

        expect(new_voucher.save).to be_falsey
        expect(new_voucher.errors[:sort]).to(
          include(I18n.t("activerecord.errors.models.voucher." \
                         "attributes.sort.only_one_active"))
        )
      end
    end

    describe "#ensure_speaker_vouchers_only_for_seminars" do
      context "whe the lecture is a seminar" do
        let(:voucher) { build(:voucher, :speaker, lecture: seminar) }

        it "does not add an error" do
          expect(voucher.save).to be_truthy
          expect(voucher.errors[:sort]).to be_empty
        end
      end

      context "when the lecture is not a seminar" do
        let(:voucher) { build(:voucher, :speaker, lecture: lecture) }

        it "rolls back and adds an error" do
          expect(voucher.save).to be_falsey
          expect(voucher.errors[:sort]).to(
            include(I18n.t("activerecord.errors.models.voucher.attributes." \
                           "sort.speaker_vouchers_only_for_seminars"))
          )
        end
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_voucher) { FactoryBot.create(:voucher) }
      let!(:expired_voucher) { FactoryBot.create(:voucher, :expired) }
      let!(:invalidated_voucher) { FactoryBot.create(:voucher, :invalidated) }

      it "includes vouchers that are not expired and not invalidated" do
        expect(Voucher.active).to include(active_voucher)
      end

      it "excludes vouchers that are expired" do
        expect(Voucher.active).not_to include(expired_voucher)
      end

      it "excludes vouchers that are invalidated" do
        expect(Voucher.active).not_to include(invalidated_voucher)
      end
    end
  end

  describe "class methods" do
    describe ".sorts_for_lecture" do
      it "returns all sorts if the lecture is a seminar" do
        expect(Voucher.sorts_for_lecture(seminar)).to eq(Voucher::SORT_HASH.keys)
      end

      it "returns all sorts except :speaker if the lecture is not a seminar" do
        expect(Voucher.sorts_for_lecture(lecture)).to eq(Voucher::SORT_HASH.keys - [:speaker])
      end
    end
  end
end
