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

    it "rolls back if there is another active voucher with the same sort for the lecture" do
      FactoryBot.create(:voucher, :tutor, lecture: lecture)
      new_voucher = build(:voucher, :tutor, lecture: lecture)

      expect(new_voucher.save).to be_falsey
      expect(new_voucher.errors[:sort]).to include(I18n.t("activerecord.errors.models.voucher." \
                                                          "attributes.sort.only_one_active"))
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns active vouchers" do
        active_voucher = FactoryBot.create(:voucher)
        expired_voucher = FactoryBot.create(:voucher, :expired)

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
end
