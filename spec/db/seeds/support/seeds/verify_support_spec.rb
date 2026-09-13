require "rails_helper"

RSpec.describe(Seeds::VerifySupport, type: :model) do
  describe ".check_content_core" do
    it "passes when at least the expected number of records are present" do
      create_list(:term, 2)

      results = described_class.check_content_core("counts" => { "terms" => 2 })

      expect(results.sole).to include(check: "terms: 2+ expected", ok: true)
    end

    it "fails when fewer records are present than expected" do
      create(:term)

      results = described_class.check_content_core("counts" => { "terms" => 2 })

      expect(results.sole).to include(check: "terms: 2+ expected", ok: false)
    end

    it "skips a group the checker has no model for" do
      results = described_class.check_content_core("counts" => { "editable_user_joins" => 3 })

      expect(results).to be_empty
    end
  end

  describe ".check_personas" do
    it "passes for a user who exists and has the seed password" do
      create(:confirmed_user, email: "teacher@mampf.edu", password: Seeds::LoadSupport::PASSWORD)

      results = described_class.check_personas("teacher" => { "email" => "teacher@mampf.edu" })

      expect(results.sole).to include(check: "teacher@mampf.edu can sign in", ok: true)
    end

    it "fails for a user who does not exist" do
      results = described_class.check_personas("teacher" => { "email" => "teacher@mampf.edu" })

      expect(results.sole).to include(check: "teacher@mampf.edu can sign in", ok: false)
    end

    it "fails for a user whose password is not the seed password" do
      create(:confirmed_user, email: "teacher@mampf.edu", password: "something-else-entirely")

      results = described_class.check_personas("teacher" => { "email" => "teacher@mampf.edu" })

      expect(results.sole).to include(check: "teacher@mampf.edu can sign in", ok: false)
    end
  end
end
