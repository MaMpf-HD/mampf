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

  describe "a message carrying markup" do
    it "escapes it" do
      user = User.new.tap { |u| u.errors.add(:base, "<script>alert(1)</script>") }

      expect(form_html(user)).to include("&lt;script&gt;")
    end

    # full_messages returns a :base message untouched, so its html_safe flag
    # would otherwise survive all the way into the page.
    it "escapes it even when a caller marked it html_safe" do
      user = User.new.tap do |u|
        u.errors.add(:base, "<img src=x onerror=alert(1)>".html_safe)
      end

      expect(form_html(user)).to include("&lt;img")
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

  describe "an error whose message is blank" do
    # errors is not empty, yet nothing printable comes out of full_messages.
    # This is the only way the generic notice is still reached.
    it "falls back to the generic notice" do
      user = User.new.tap { |u| u.errors.add(:base, "") }

      expect(form_html(user)).to include(I18n.t("errors.unknown").strip)
    end
  end
end
