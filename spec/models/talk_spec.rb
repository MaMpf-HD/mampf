require "rails_helper"

RSpec.describe(Talk, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:valid_talk)).to be_valid
  end

  # Test validations
  it "is invalid without a lecture" do
    talk = FactoryBot.build(:valid_talk)
    talk.lecture = nil
    expect(talk).to be_invalid
  end
  it "is invalid without a title" do
    talk = FactoryBot.build(:valid_talk)
    talk.title = nil
    expect(talk).to be_invalid
  end

  # Test traits

  describe "talk with date" do
    before(:all) do
      @talk = FactoryBot.build(:valid_talk, :with_date)
    end
    it "is valid" do
      expect(@talk).to be_valid
    end
    it "has a date" do
      expect(@talk.dates.first).to be_kind_of(Date)
    end
  end

  describe "talk with speaker" do
    before(:all) do
      @talk = FactoryBot.build(:valid_talk, :with_speaker)
    end
    it "is valid" do
      expect(@talk).to be_valid
    end
    it "has a speaker" do
      expect(@talk.speakers).not_to be_nil
    end
  end

  # Test methods

  describe "#talk" do
    it "returns itself" do
      talk = FactoryBot.build(:talk)
      expect(talk.talk).to eq(talk)
    end
  end

  describe "#lesson" do
    it "returns nil" do
      talk = FactoryBot.build(:talk)
      expect(talk.lesson).to be_nil
    end
  end

  context "title methods" do
    before :each do
      I18n.with_locale(:de) do
        course = FactoryBot.build(:course, title: "Algebra 1",
                                           short_title: "Alg1")
        term = FactoryBot.build(:term, season: "SS", year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        FactoryBot.create(:talk, lecture: lecture, title: "total bs")
        @talk = FactoryBot.create(:talk, lecture: lecture,
                                         title: "even more bs")
      end
    end

    describe "#to_label" do
      it "returns the correct label" do
        I18n.with_locale(:de) do
          expect(@talk.to_label).to eq("Vortrag 2. even more bs")
        end
      end
    end

    describe "#title_for_viewers" do
      it "returns the correct title" do
        expect(@talk.title_for_viewers)
          .to eq("(V) Alg1 SS 20, Vortrag 2. even more bs")
      end
    end

    describe "#long_title" do
      it "returns the correct title" do
        expect(@talk.long_title)
          .to eq("(V) Alg1 SS 20, Vortrag 2. even more bs")
      end
    end

    describe "#local_title_for_viewers" do
      it "returns the correct title" do
        expect(@talk.local_title_for_viewers)
          .to eq("Vortrag 2. even more bs")
      end
    end

    describe "#short_title_with_lecture_date" do
      it "returns the correct title" do
        expect(@talk.short_title_with_lecture_date)
          .to eq("(V) Alg1 SS 20, Vortrag 2. even more bs")
      end
    end

    describe "#card_header" do
      it "returns the correct title" do
        expect(@talk.card_header)
          .to eq("(V) Alg1 SS 20, Vortrag 2. even more bs")
      end
    end

    describe "#compact_title" do
      it "returns the correct compact title" do
        expect(@talk.compact_title).to eq("V.Alg1.SS20.V2")
      end
    end
  end

  describe "#given_by?" do
    it "returns true if the user is a speaker of the talk" do
      talk = FactoryBot.build(:valid_talk)
      user = FactoryBot.build(:confirmed_user)
      talk.speakers << user
      expect(talk.given_by?(user)).to be(true)
    end
  end

  context "locale methods" do
    before :each do
      I18n.with_locale(:de) do
        course = FactoryBot.build(:course, title: "Algebra 1",
                                           short_title: "Alg1")
        term = FactoryBot.build(:term, season: "SS", year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             locale: "br")
        @talk = FactoryBot.create(:talk, lecture: lecture)
      end
    end

    describe "#locale" do
      it "returns the locale of the lecture" do
        expect(@talk.locale).to eq("br")
      end
    end
  end

  describe "#media_scope" do
    it "returns the lecture associated to the talk" do
      lecture = FactoryBot.build(:lecture, released: "all")
      talk = FactoryBot.build(:talk, lecture: lecture)
      expect(talk.media_scope).to eq(lecture)
    end
  end

  context "position methods" do
    before :each do
      lecture = FactoryBot.build(:lecture)
      @talk1 = FactoryBot.create(:talk, lecture: lecture)
      @talk2 = FactoryBot.create(:talk, lecture: lecture)
      @talk3 = FactoryBot.create(:talk, lecture: lecture)
    end

    describe "#number" do
      it "returns the number of the talk" do
        expect(@talk3.number).to eq(3)
      end
    end

    describe "#previous" do
      it "returns the previous talk if the talk is not the first one" do
        expect(@talk3.previous).to eq(@talk2)
      end

      it "returns nil if the talk is the first one" do
        expect(@talk1.previous).to be(nil)
      end
    end

    describe "#next" do
      it "returns the next talk if the talk is not the last one" do
        expect(@talk2.next).to eq(@talk3)
      end

      it "returns nil if the talk is the last one" do
        expect(@talk3.next).to be(nil)
      end
    end

    describe "#proper_media" do
      it "returns the array of media associated to the talk that are neither " \
         "Questions nor Remarks" do
        talk = FactoryBot.create(:valid_talk)
        medium1 = FactoryBot.create(:talk_medium, teachable: talk,
                                                  sort: "Kaviar")
        medium2 = FactoryBot.create(:talk_medium, teachable: talk,
                                                  sort: "Sesam")
        FactoryBot.create(:talk_medium, teachable: talk,
                                        sort: "Question")
        FactoryBot.create(:talk_medium, teachable: talk,
                                        sort: "Remark")
        expect(talk.proper_media).to match_array([medium1, medium2])
      end
    end

    describe "#card_header_path" do
      it "returns the path for the talk if the user is subscribed to the " \
         "seminar" do
        lecture = FactoryBot.build(:lecture)
        user = FactoryBot.create(:confirmed_user)
        user.lectures << lecture
        talk = FactoryBot.create(:valid_talk, lecture: lecture)
        expect(talk.card_header_path(user)).to include("talks/")
      end

      it "returns nil if user is not subscribed to the seminar" do
        lecture = FactoryBot.build(:lecture)
        user = FactoryBot.create(:confirmed_user)
        talk = FactoryBot.create(:valid_talk, lecture: lecture)
        expect(talk.card_header_path(user)).to be_nil
      end
    end
  end
end
