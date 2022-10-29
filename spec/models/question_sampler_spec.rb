# frozen_string_literal: true

RSpec.describe QuestionSampler, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:question_sampler)).to be_kind_of(QuestionSampler)
  end

  describe '#sample!' do
    before :all do
      @questions = Question.where(id: FactoryBot.create_list(:valid_question, 4)
                                                .map(&:id))
    end

    it 'returns [] if no tags are given' do
      question_sampler = FactoryBot.build(:question_sampler,
                                          questions: @questions)
      expect(question_sampler.sample!).to eq []
    end

    it 'returns an array with the correct length if not enough questions match'\
       ' the tags' do
      tags = Tag.where(id: FactoryBot.create_list(:tag, 3).map(&:id))
      @questions[0].tags << tags[0]
      @questions[1].tags << tags[1]
      question_sampler = FactoryBot.build(:question_sampler,
                                          questions: @questions,
                                          tags: tags,
                                          count: 3)
      expect(question_sampler.sample!.size).to eq 2
    end

    context 'in a simple example' do
      before :all do
        tags = Tag.where(id: FactoryBot.create_list(:tag, 3).map(&:id))
        @questions[0].tags << tags[0]
        @questions[1].tags << tags[1]
        @questions[2].tags << tags[2]
        @questions[3].tags << tags[2]
        @question_sampler = FactoryBot.build(:question_sampler,
                                             questions: @questions,
                                             tags: tags,
                                             count: 3)
        @sample = @question_sampler.sample!
      end

      it 'returns an array with the correct length' do
        expect(@sample.size).to eq 3
      end

      it 'does not return duplicates' do
        expect(@sample.uniq.size).to eq @sample.size
      end

      it 'returns a list of questions that is a subset of the given list' do
        expect(@sample - @questions.pluck(:id)).to eq []
      end
    end
  end
end
