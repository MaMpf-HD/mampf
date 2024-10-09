require "rails_helper"
RSpec.describe(VouchersController, type: :controller) do
  let(:teacher) { FactoryBot.create(:confirmed_user) }
  let(:generic_user) { FactoryBot.create(:confirmed_user) }
  let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }
  let(:role) { :tutor }

  context "As an authorized user" do
    before do
      sign_in teacher
    end

    describe "POST #create" do
      it "creates a new voucher" do
        expect do
          post(:create, params: { lecture_id: lecture.id, role: role })
        end.to change(lecture.vouchers, :count).by(1)
      end
    end

    describe "POST #invalidate" do
      it "invalidates the voucher" do
        voucher = FactoryBot.create(:voucher, lecture: lecture)
        post(:invalidate, params: { id: voucher.id })
        voucher.reload
        expect(Voucher.find(voucher.id).invalidated_at).not_to be_nil
      end
    end
  end

  context "As an unauthorized user" do
    before do
      sign_in generic_user
    end

    describe "POST #create" do
      it "does not create a new voucher" do
        expect do
          post(:create, params: { lecture_id: lecture.id, role: role })
        end.not_to change(lecture.vouchers, :count)
      end

      it "redirects to root path" do
        post(:create, params: { lecture_id: lecture.id, role: role })
        expect(response).to redirect_to(root_path)
      end
    end

    describe "POST #invalidate" do
      it "does not invalidate the voucher" do
        voucher = FactoryBot.create(:voucher, lecture: lecture)
        post(:invalidate, params: { id: voucher.id })
        voucher.reload
        expect(voucher.invalidated_at).to be_nil
      end
    end

    describe "POST #verify" do
      it "displays an error message if the secure hash is incorrect" do
        post(:verify, params: { secure_hash: "incorrect_hash" })
        expect(flash[:alert]).to eq(I18n.t("controllers.voucher_invalid"))
      end

      it "redirects to edit profile path if the secure hash is incorrect" do
        post(:verify, params: { secure_hash: "incorrect_hash" })
        expect(response).to redirect_to(edit_profile_path)
      end
    end

    describe "POST #redeem" do
      it "it does not redeem if the secure hash is incorrect" do
        expect do
          post(:redeem, params: { secure_hash: "incorrect_hash" })
        end.not_to change(Redemption, :count)
      end

      it "displays an error message if the secure hash is incorrect" do
        post(:redeem, params: { secure_hash: "incorrect_hash" })
        expect(flash[:alert]).to eq(I18n.t("controllers.voucher_invalid"))
      end

      it "redeems if voucher secure hash is correct" do
        voucher = FactoryBot.create(:voucher, lecture: lecture)
        expect do
          post(:redeem, params: { secure_hash: voucher.secure_hash })
        end.to change(Redemption, :count).by(1)
      end
    end
  end
end
