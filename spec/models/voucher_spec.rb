require "rails_helper"

RSpec.describe(Voucher, type: :model) do
  let(:lecture) { FactoryBot.create(:lecture) }

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
  end

  describe "scopes" do
    describe ".active" do
      it "returns active vouchers" do
        active_voucher = FactoryBot.create(:voucher)
        expired_voucher = FactoryBot.create(:voucher, :expired)

        expect(expired_voucher.expired?).to be(true)
        expect(Voucher.active.count).to eq(1)
        expect(Voucher.active).to include(active_voucher)
        expect(Voucher.active).not_to include(expired_voucher)
      end
    end
  end

  describe "instance methods" do
    describe "#expired?" do
      it "returns true if the voucher has expired" do
        voucher = FactoryBot.build(:voucher, expires_at: Time.now - 1.day)
        expect(voucher.expired?).to be(true)
      end

      it "returns false if the voucher has not expired" do
        voucher = FactoryBot.build(:voucher, expires_at: Time.now + 1.day)
        expect(voucher.expired?).to be(false)
      end
    end

    describe "#active?" do
      it "returns true if the voucher is active" do
        voucher = FactoryBot.build(:voucher, expires_at: Time.now + 1.day)
        expect(voucher.active?).to be(true)
      end

      it "returns false if the voucher is not active" do
        voucher = FactoryBot.build(:voucher, expires_at: Time.now - 1.day)
        expect(voucher.active?).to be(false)
      end
    end
  end

  describe "custom validations" do
    describe "#ensure_no_other_active_voucher" do
      it "adds an error if there is another active voucher with the same " \
         "sort for the lecture" do
        FactoryBot.create(:voucher, lecture: lecture, sort: :tutor)
        voucher = FactoryBot.build(:voucher, lecture: lecture, sort: :tutor)

        expect(voucher).not_to be_valid
        expect(voucher.errors[:sort]).to include(I18n.t("activerecord.errors.models.voucher." \
                                                        "attributes.sort.only_one_active"))
      end

      it "does not add an error if there is no other active voucher with the " \
         "same sort for the lecture" do
        voucher = FactoryBot.build(:voucher, lecture: lecture, sort: :tutor)

        expect(voucher).to be_valid
        expect(voucher.errors[:sort]).to be_empty
      end
    end
  end
end
