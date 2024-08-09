require "rails_helper"
RSpec.describe(VouchersController, type: :controller) do
  let(:user) { FactoryBot.create(:user) }
  let(:lecture) { FactoryBot.create(:lecture, teacher: user) }
  let(:voucher) { FactoryBot.create(:voucher, lecture: lecture) }

  before do
    sign_in user
  end

  describe "POST #create" do
    it "creates a new voucher" do
      expect do
        post(:create, params: { voucher: { lecture_id: lecture.id, sort: "tutor" } })
      end.to change(Voucher, :count).by(1)
    end
  end

  describe "DELETE #destroy" do
    it "deletes the voucher" do
      expect do
        delete(:destroy, params: { id: voucher.id })
      end.to change(Voucher, :count).by(-1)
    end
  end
end
