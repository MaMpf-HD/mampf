require "rails_helper"

RSpec.describe(RedemptionsHelper, type: :helper) do
  describe "#redemption_notification_details" do
    let(:user) do
      create(:confirmed_user,
             name: 'Ada <b class="big" name="title">Lovelace</b> & Co.')
    end

    [:tutor, :editor, :teacher].each do |role|
      it "names the user as the text that was typed (#{role} voucher)" do
        redemption = Redemption.create!(user: user,
                                        voucher: create(:voucher, role))

        details = Nokogiri::HTML5.fragment(
          helper.redemption_notification_details(redemption)
        )

        expect(details.text).to include(user.info)
        expect(details.elements).to be_empty
      end
    end
  end
end
