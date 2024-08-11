require "rails_helper"
RSpec.describe(VouchersController, type: :controller) do
  let(:teacher) { FactoryBot.create(:confirmed_user) }
  let(:generic_user) { FactoryBot.create(:confirmed_user) }
  let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }
  let(:sort) { :tutor }

  context "As an authorized user" do
    before do
      sign_in teacher
    end

    describe "POST #create" do
      it "creates a new voucher" do
        expect do
          post(:create, params: { lecture_id: lecture.id, sort: sort })
        end.to change(lecture.vouchers, :count).by(1)
      end
    end

    describe "DELETE #destroy" do
      it "deletes the voucher" do
        voucher = FactoryBot.create(:voucher, lecture: lecture)
        expect do
          delete(:destroy, params: { id: voucher.id })
        end.to change(lecture.vouchers, :count).by(-1)
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
          post(:create, params: { lecture_id: lecture.id, sort: sort })
        end.not_to change(lecture.vouchers, :count)
      end

      it "redirects to root path" do
        post(:create, params: { lecture_id: lecture.id, sort: sort })
        expect(response).to redirect_to(root_path)
      end
    end

    describe "DELETE #destroy" do
      it "does not delete the voucher" do
        voucher = FactoryBot.create(:voucher, lecture: lecture)
        expect do
          delete(:destroy, params: { id: voucher.id })
        end.not_to change(lecture.vouchers, :count)
      end
    end
  end
end
