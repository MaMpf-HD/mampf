require "rails_helper"

RSpec.describe(Term, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:term)).to be_valid
  end

  # test validations

  it "is invalid without a season" do
    term = FactoryBot.build(:term, season: nil)
    expect(term).to be_invalid
  end
  it "is invalid without a year" do
    term = FactoryBot.build(:term, year: nil)
    expect(term).to be_invalid
  end
  it "is invalid if season is not SS or WS" do
    term = FactoryBot.build(:term, season: "Spring")
    expect(term).to be_invalid
  end
  it "is invalid if year is not a number" do
    term = FactoryBot.build(:term, year: "hello")
    expect(term).to be_invalid
  end
  it "is invalid if year is not an integer" do
    term = FactoryBot.build(:term, year: 2017.25)
    expect(term).to be_invalid
  end
  it "is invalid if year is lower than 2000" do
    term = FactoryBot.build(:term, year: 1999)
    expect(term).to be_invalid
  end
  it "is invalid with duplicate season and year" do
    FactoryBot.create(:term, season: "SS", year: 2017)
    term = FactoryBot.build(:term, season: "SS", year: 2017)
    expect(term).to be_invalid
  end

  # test traits

  describe "summer term" do
    before :each do
      @term = FactoryBot.build(:term, :summer)
    end
    it "has a valid factory" do
      expect(@term).to be_valid
    end
    it "is a summer term" do
      expect(@term.season).to eq("SS")
    end
  end

  describe "#dashboard_param" do
    it "is season + two-digit year for a summer term" do
      expect(build(:term, season: "SS", year: 2025).dashboard_param).to eq("SS25")
    end

    it "spans both years for a winter term" do
      expect(build(:term, season: "WS", year: 2025).dashboard_param)
        .to eq("WS25-26")
    end

    it "wraps the second year across the century" do
      expect(build(:term, season: "WS", year: 2099).dashboard_param)
        .to eq("WS99-00")
    end
  end

  describe ".from_dashboard_param" do
    let!(:summer) { create(:term, season: "SS", year: 2025) }
    let!(:winter) { create(:term, season: "WS", year: 2025) }

    it "round-trips a #dashboard_param slug" do
      expect(Term.from_dashboard_param(summer.dashboard_param)).to eq(summer)
      expect(Term.from_dashboard_param(winter.dashboard_param)).to eq(winter)
    end

    it "is case-insensitive and ignores the redundant winter end year" do
      expect(Term.from_dashboard_param("ws25-99")).to eq(winter)
    end

    it "still accepts a bare id" do
      expect(Term.from_dashboard_param(summer.id.to_s)).to eq(summer)
    end

    it "is nil for a blank or unknown value" do
      expect(Term.from_dashboard_param(nil)).to be_nil
      expect(Term.from_dashboard_param("SS99")).to be_nil
      expect(Term.from_dashboard_param("nonsense")).to be_nil
    end
  end

  # test methods - NEEDS TO BE REFACTORED

  # describe '#begin_date' do
  #   context 'if the term is a winter term' do
  #     it 'returns the correct begin date' do
  #       term = FactoryBot.build(:term, season: 'WS', year: 2017)
  #       expect(term.begin_date).to eq Date.new(2017, 10, 1)
  #     end
  #   end
  #   context 'if the term is a summer term' do
  #     it 'returns the correct begin date' do
  #       term = FactoryBot.build(:term, season: 'SS', year: 2017)
  #       expect(term.begin_date).to eq Date.new(2017, 4, 1)
  #     end
  #   end
  # end

  # describe '#end_date' do
  #   context 'if the term is a winter term' do
  #     it 'returns the correct end date' do
  #       term = FactoryBot.build(:term, season: 'WS', year: 2017)
  #       expect(term.end_date).to eq Date.new(2018, 3, 31)
  #     end
  #   end
  #   context 'if the term is a summer term' do
  #     it 'returns the correct end date' do
  #       term = FactoryBot.build(:term, season: 'SS', year: 2017)
  #       expect(term.end_date).to eq Date.new(2017, 9, 30)
  #     end
  #   end
  # end

  # describe '#to_label' do
  #   it 'returns the correct label if the term is a winter term' do
  #     term = FactoryBot.build(:term, season: 'WS', year: 2017)
  #     expect(term.to_label).to eq('WS 2017/18')
  #   end
  #   it 'returns the correct label if the term is a summer term' do
  #     term = FactoryBot.build(:term, season: 'SS', year: 2017)
  #     expect(term.to_label).to eq('SS 2017')
  #   end
  # end

  # describe '#to_label_short' do
  #   it 'returns the correct label if the term is a winter term' do
  #     term = FactoryBot.build(:term, season: 'WS', year: 2017)
  #     expect(term.to_label_short).to eq('WS 17/18')
  #   end
  #   it 'returns the correct label if the term is a summer term' do
  #     term = FactoryBot.build(:term, season: 'SS', year: 2017)
  #     expect(term.to_label_short).to eq('SS 17')
  #   end
  # end

  describe "#next" do
    context "when term is a summer term" do
      it "returns the winter term of the same year" do
        summer = create(:term, season: "SS", year: 2023)
        winter = create(:term, season: "WS", year: 2023)

        expect(summer.next).to eq(winter)
      end

      it "returns nil if next term does not exist" do
        summer = create(:term, season: "SS", year: 2023)

        expect(summer.next).to be_nil
      end
    end

    context "when term is a winter term" do
      it "returns the summer term of the next year" do
        winter = create(:term, season: "WS", year: 2023)
        next_summer = create(:term, season: "SS", year: 2024)

        expect(winter.next).to eq(next_summer)
      end

      it "returns nil if next term does not exist" do
        winter = create(:term, season: "WS", year: 2023)

        expect(winter.next).to be_nil
      end
    end
  end
end
