require "rails_helper"

RSpec.describe("Roster::SelfMaterializationController", type: :request) do
  let(:lecture) { create(:lecture, locale: I18n.default_locale) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }

  before do
    Flipper.enable(:roster_maintenance)
    create(:editable_user_join, user: editor, editable: lecture)
    editor.reload
    lecture.reload
  end
end
