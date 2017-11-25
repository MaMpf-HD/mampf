require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
  describe '#similar_tags' do
    it 'returns a correct list of similar tags' do
      tags = FactoryBot.create_list(:tag, 3)
      tags[0].update(title: 'Zufallszahl')
      tags[1].update(title: 'Zufalszahl')
      tags[2].update(title: 'was ganz anderes')
      expect(similar_tags('Zufallszahl').to_a).to eql(tags.first(2))
    end
  end
end
