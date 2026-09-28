require "rails_helper"

RSpec.describe(PersonalDataChange, type: :model) do
  let(:user) { create(:confirmed_user) }

  it "needs somebody who made the correction" do
    change = described_class.new(user: user, field: "last_name", new_value: "Lasker")

    expect(change).not_to be_valid
  end

  it "cannot be edited once recorded" do
    change = described_class.create!(user: user, editor: create(:confirmed_user),
                                     field: "last_name", new_value: "Lasker")

    expect { change.update!(new_value: "Noether") }
      .to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "goes with the user it belongs to" do
    described_class.create!(user: user, editor: create(:confirmed_user),
                            field: "last_name", new_value: "Lasker")

    expect { user.destroy }.to change(described_class, :count).by(-1)
  end
end
