require "rails_helper"

RSpec.describe("Vouchers", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:voucher) { create(:voucher, :tutor, lecture: lecture) }

  before { sign_in user }

  def verify
    post(verify_voucher_path, params: { secure_hash: voucher.secure_hash }, xhr: true)
  end

  describe "the tutor voucher's page" do
    # The tutorial one sits in is not on offer; it must not close the door
    # when it is the only one, since a tutor without a tutorial is put on one
    # by the teacher afterwards.
    it "offers to redeem without a tutorial when the only one is the reader's own" do
      tutorial = create(:tutorial, lecture: lecture)
      create(:lecture_membership, lecture: lecture, user: user)
      create(:tutorial_membership, tutorial: tutorial, user: user)

      verify

      expect(response.body).to include(I18n.t("profile.own_tutorial_not_offered").strip)
      expect(response.body).to include(I18n.t("profile.no_tutorials_redemption").strip)
      expect(response.body).to include(I18n.t("profile.redeem_voucher"))
      expect(response.body).not_to include(CGI.escapeHTML(tutorial.title))
    end

    it "offers the open tutorials, and not the reader's own" do
      own = create(:tutorial, lecture: lecture, title: "Mo 10")
      other = create(:tutorial, lecture: lecture, title: "Tue 14")
      create(:lecture_membership, lecture: lecture, user: user)
      create(:tutorial_membership, tutorial: own, user: user)

      verify

      expect(response.body).to include("Tue 14")
      expect(response.body).not_to include("Mo 10")
      expect(response.body).to include(I18n.t("profile.tutorials_available").strip[0, 40])
      expect(other).to be_present
    end

    it "only offers to cancel once the voucher has been redeemed and nothing is open" do
      own = create(:tutorial, lecture: lecture)
      create(:lecture_membership, lecture: lecture, user: user)
      create(:tutorial_membership, tutorial: own, user: user)
      voucher.redemptions.create!(user: user)

      verify

      expect(response.body).to include(I18n.t("profile.already_tutor_by_redemption").strip)
      expect(response.body).not_to include(I18n.t("profile.redeem_voucher"))
    end
  end
end
