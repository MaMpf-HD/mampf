require "rails_helper"

RSpec.describe("Values in script views", type: :request) do
  # Returns the value as a script view has to print it inside a string whose
  # receiver takes text, like a form field: escaped with `j` and not for HTML,
  # so that the field shows `&` and quotes as typed.
  def in_script_string(value)
    ApplicationController.helpers.j(value)
  end

  describe "GET /items/:id/display" do
    let(:description) { "O'Neil & Zorn \\ notes\\" }
    let(:link) { "https://example.org/o'neil?notes=(a)&page=2\\" }
    let(:explanation) { "See O'Neil's notes,\nchapter 2 (\\S 3)\\" }
    let(:item) do
      create(:item, sort: "link", medium: nil, description: description,
                    link: link, explanation: explanation)
    end

    # Returns the call that fills the given field with the value, as a pattern.
    def filling(field, value)
      Regexp.escape("$('##{field}').val('#{in_script_string(value)}');")
    end

    before do
      sign_in create(:confirmed_user)
      get display_item_path(item), xhr: true
    end

    it "answers with a script" do
      expect(response).to have_http_status(:ok)
    end

    it "prints the explanation as one string" do
      expect(response.body)
        .to match(/#{filling("referral_explanation", explanation)}/)
    end

    it "prints description and link as two strings following each other" do
      description_call = filling("referral_description", description)
      link_call = filling("referral_link", link)
      expect(response.body).to match(/#{description_call}\s+#{link_call}/)
    end
  end

  describe "GET /tags/render_tag_title" do
    let(:title) { "O'Neil & Zorn \\ notes\\" }
    let(:other_title) { "Zorn's lemma\n(see \\S 2)" }
    let(:tag) { create(:tag, title: title) }
    let(:identified_tag) { create(:tag, title: other_title) }

    # Returns the option a title is printed as, as a pattern: value and text
    # follow each other and close the option.
    def option_for(title)
      string = Regexp.escape("'#{in_script_string(title)}'")
      /value: #{string},\s+text: #{string}\s+\}\)\);/
    end

    before do
      sign_in create(:confirmed_user, admin: true)
      get render_tag_title_path,
          params: { tag_id: tag.id, identified_tag_id: identified_tag.id },
          xhr: true
    end

    it "answers with a script" do
      expect(response).to have_http_status(:ok)
    end

    it "prints each title as value and text of one option" do
      expect(response.body).to match(option_for(title))
      expect(response.body).to match(option_for(other_title))
    end
  end

  describe "GET /media/:id/render_import_media" do
    before do
      sign_in create(:confirmed_user, admin: true, consents: true)
      get render_import_media_path("12 notes"), xhr: true
    end

    it "prints the id as a number" do
      expect(response.body).to match(/^\s*id = 12;$/)
    end
  end
end
