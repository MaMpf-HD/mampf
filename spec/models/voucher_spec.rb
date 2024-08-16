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
end
