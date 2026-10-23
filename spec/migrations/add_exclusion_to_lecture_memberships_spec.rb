require "rails_helper"
require Rails.root.join("db/migrate/20261023000000_add_exclusion_to_lecture_memberships")

RSpec.describe(AddExclusionToLectureMemberships) do
  it "refuses to go down while someone has left a lecture" do
    create(:lecture_membership).exclude!

    expect { described_class.new.down }.to raise_error(ActiveRecord::IrreversibleMigration)
    expect(LectureMembership.column_names).to include("excluded_at")
  end
end
