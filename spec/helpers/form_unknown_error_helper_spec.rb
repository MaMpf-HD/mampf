require "rails_helper"

RSpec.describe(FormUnknownErrorHelper, type: :helper) do
  def form_html(object, with_field: false)
    helper.form_with(model: object, url: "/somewhere") do |f|
      helper.concat(f.text_field(:name)) if with_field
      helper.concat(f.submit("Speichern"))
    end
  end

  describe "an error that belongs to no field" do
    let(:user) do
      User.new.tap { |u| u.errors.add(:base, "Du bist bereits angemeldet") }
    end

    it "names the reason" do
      expect(form_html(user)).to include("Du bist bereits angemeldet")
    end

    it "does not blame the server" do
      expect(form_html(user)).not_to include(I18n.t("errors.unknown").strip)
    end
  end

  describe "an error a field already shows" do
    let(:user) do
      User.new.tap { |u| u.errors.add(:name, "muss ausgefüllt werden") }
    end

    it "leaves the whole-form message out" do
      expect(form_html(user, with_field: true)).not_to include("invalid-feedback d-block")
    end
  end

  describe "a form object without errors" do
    it "adds nothing" do
      expect(form_html(User.new)).not_to include("invalid-feedback")
    end
  end
end
