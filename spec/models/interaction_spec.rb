# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Interaction, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:interaction)).to be_valid
  end

  # describe traits

  describe 'with stuff' do
    before :all do
      @interaction = FactoryBot.build(:interaction, :with_stuff)
    end
    it 'has a session id' do
      expect(@interaction.session_id).to be_truthy
    end
    it 'has a referrer url' do
      expect(@interaction.referrer_url).to be_truthy
    end
    it 'has a full path' do
      expect(@interaction.full_path).to be_truthy
    end
  end
end
