require "rails_helper"

RSpec.describe(MathiMailer) do
  describe "#data_provide_email" do
    let(:user) do
      create(:confirmed_user, locale: "en", first_name: "Ada", last_name: "Lovelace",
                              matriculation_number: "1234567", uni_id: "ab123",
                              name_in_tutorials: "Ada L.",
                              email_for_submission_upload: true,
                              email_for_correction_upload: false)
    end
    let(:body) do
      I18n.with_locale(:en) { described_class.data_provide_email(user).html_part.body.decoded }
    end

    it "lists the personal data the user entered" do
      expect(body).to include("First name: Ada", "Last name: Lovelace",
                              "Matriculation number: 1234567", "Uni ID: ab123")
    end

    it "shows each setting and the name in tutorials as stored" do
      expect(body).to include("Emails for correction upload: false",
                              "Name in tutorials: Ada L.")
    end
  end
end
