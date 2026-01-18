require "rails_helper"

RSpec.describe(Lecture, type: :model) do
  describe "Rosters::Rosterable" do
    it_behaves_like "a rosterable model"
  end

  it "has a valid factory" do
    expect(FactoryBot.build(:lecture)).to be_valid
  end

  # Test validations  -- SOME ARE MISSING

  it "is invalid without a course" do
    lecture = FactoryBot.build(:lecture, course: nil)
    expect(lecture).to be_invalid
  end
  it "is invalid without a teacher" do
    lecture = FactoryBot.build(:lecture, teacher: nil)
    expect(lecture).to be_invalid
  end
  it "is invalid if duplicate combination of course, teacher and term" do
    course = FactoryBot.create(:course)
    teacher = FactoryBot.create(:confirmed_user)
    term = FactoryBot.create(:term)
    FactoryBot.create(:lecture, course: course, teacher: teacher, term: term)
    lecture = FactoryBot.build(:lecture, course: course, teacher: teacher,
                                         term: term)
    expect(lecture).to be_invalid
  end

  # Test traits

  describe "lecture with organizational stuff" do
    before :each do
      @lecture = FactoryBot.build(:lecture, :with_organizational_stuff)
    end
    it "has a valid factory" do
      expect(@lecture).to be_valid
    end
    it "has organizational flag set to true" do
      expect(@lecture.organizational).to be(true)
    end
    it "has an organizational concept" do
      expect(@lecture.organizational_concept).to be_truthy
    end
  end
  describe "lecture which is released for all" do
    before :each do
      @lecture = FactoryBot.build(:lecture, :released_for_all)
    end
    it "has a valid factory" do
      expect(@lecture).to be_valid
    end
    it "is released for all" do
      expect(@lecture.released).to eq("all")
    end
  end
  describe "term independent lecture" do
    before :each do
      @lecture = FactoryBot.build(:lecture, :term_independent)
    end
    it "has a valid factory" do
      expect(@lecture).to be_valid
    end
    it "has no associated term" do
      expect(@lecture.term).to be_nil
    end
  end
  describe "with table of contents" do
    before :each do
      @lecture = FactoryBot.build(:lecture, :with_toc)
    end
    it "has 3 chapters" do
      expect(@lecture.chapters.size).to eq(3)
    end
    it "has 3 sections in each chapter" do
      expect(@lecture.chapters.map { |c| c.sections.size }).to eq([3, 3, 3])
    end
  end
  describe "with sparse table of contents" do
    before :each do
      @lecture = FactoryBot.build(:lecture, :with_sparse_toc)
    end
    it "has one chapter" do
      expect(@lecture.chapters.size).to eq(1)
    end
    it "has one sections in each chapter" do
      expect(@lecture.chapters.map { |c| c.sections.size }).to eq([1])
    end
  end

  describe "#stale?" do
    context "when there is no active term" do
      it "returns false" do
        lecture = FactoryBot.build(:lecture)
        expect(lecture.stale?).to be(false)
      end
    end

    context "when there is an active term" do
      let(:year) { 2024 }

      before(:each) do
        FactoryBot.create(:term, :summer, :active, year: year)
      end

      context "and there is no term associated with the lecture" do
        it "returns true" do
          lecture = FactoryBot.build(:lecture, :term_independent)
          expect(lecture.stale?).to be(true)
        end
      end

      context "and the lecture term begin date is before the active term" \
              "begin date minus 1 year" do
        let(:lecture_term) { FactoryBot.build(:term, :summer, year: year - 1) }

        it "returns true" do
          lecture = FactoryBot.build(:lecture, term: lecture_term)
          expect(lecture.stale?).to be(true)
        end
      end

      context "when the lecture term begin date is not older than the" \
              "active term begin date minus 1 year" do
        let(:lecture_term) { FactoryBot.build(:term, :winter, year: year - 1) }

        it "returns false" do
          lecture = FactoryBot.build(:lecture, term: lecture_term)
          expect(lecture.stale?).to be(false)
        end
      end
    end
  end

  describe "#active_voucher_of_role" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:role) { :tutor }

    context "when there is an active voucher of the specified role" do
      let!(:active_voucher) do
        FactoryBot.create(:voucher, role: role, lecture: lecture)
      end

      it "returns the voucher" do
        expect(lecture.active_voucher_of_role(role)).to eq(active_voucher)
      end
    end

    context "when there is no active voucher of the specified role" do
      let!(:inactive_voucher) do
        FactoryBot.create(:voucher, :expired, role: role, lecture: lecture)
      end

      it "returns nil" do
        expect(lecture.active_voucher_of_role(role)).to be(nil)
      end
    end
  end

  # Test methods -- NEEDS TO BE REFACTORED

  # describe '#tags' do
  #   it 'returns the correct tags for the lecture' do
  #     tags = FactoryBot.create_list(:tag, 3)
  #     course = FactoryBot.create(:course, tags: tags)
  #     additional_tags = FactoryBot.create_list(:tag, 2)
  #     disabled_tags = [tags[0], tags[1]]
  #     lecture = FactoryBot.create(:lecture, course: course,
  #                                           additional_tags: additional_tags,
  #                                           disabled_tags: disabled_tags)
  #     expect(lecture.tags).to match_array([tags[2], additional_tags[0],
  #                                          additional_tags[1]])
  #   end
  # end
  # describe '#sections' do
  #   it 'returns the correct sections' do
  #     lecture = FactoryBot.build(:lecture)
  #     first_chapter = FactoryBot.create(:chapter, :with_sections,
  #                                       lecture: lecture)
  #     second_chapter = FactoryBot.create(:chapter, :with_sections,
  #                                        lecture: lecture)
  #     sections = first_chapter.sections + second_chapter.sections
  #     expect(lecture.sections.to_a).to match_array(sections)
  #   end
  # end
  # describe '#to_label' do
  #   it 'returns the correct label' do
  #     course = FactoryBot.create(:course, title: 'Usual bs')
  #     term =   FactoryBot.create(:term)
  #     lecture = FactoryBot.build(:lecture, course: course, term: term)
  #     expect(lecture.to_label).to eq('Usual bs, ' + term.to_label)
  #   end
  # end
  # describe '#short_title' do
  #   it 'returns the correct short_title' do
  #     course = FactoryBot.create(:course, short_title: 'bs')
  #     term =   FactoryBot.create(:term)
  #     lecture = FactoryBot.build(:lecture, course: course, term: term)
  #     expect(lecture.short_title).to eq('bs ' + term.to_label_short)
  #   end
  # end
  # describe '#title' do
  #   it 'returns the correct title' do
  #     course = FactoryBot.create(:course, title: 'Usual bs')
  #     term =   FactoryBot.create(:term)
  #     lecture = FactoryBot.build(:lecture, course: course, term: term)
  #     expect(lecture.title).to eq('Usual bs, ' + term.to_label)
  #   end
  # end
  # describe '#term_teacher_info' do
  #   it 'returns the correct information' do
  #     term =   FactoryBot.create(:term)
  #     teacher = FactoryBot.create(:user, name: 'Luke Skywalker')
  #     lecture = FactoryBot.build(:lecture, teacher: teacher, term: term)
  #     expect(lecture.term_teacher_info).to eq(term.to_label +
  #                                               ', Luke Skywalker')
  #   end
  # end
  # describe '#description' do
  #   it 'returns the correct description' do
  #     course = FactoryBot.create(:course, title: 'Usual bs')
  #     term =   FactoryBot.create(:term)
  #     lecture = FactoryBot.build(:lecture, course: course, term: term)
  #     expect(lecture.description).to eq({ general: 'Usual bs, ' +
  #                                                     term.to_label })
  #   end
  # end

  describe "Registration::Campaignable" do
    let(:lecture) { FactoryBot.create(:lecture) }

    it "has many registration_campaigns" do
      expect(lecture).to respond_to(:registration_campaigns)
    end

    it "can create a registration_campaign" do
      campaign = lecture.registration_campaigns.create(
        description: "Test Campaign",
        allocation_mode: :first_come_first_served,
        status: :draft,
        registration_deadline: 1.week.from_now
      )

      expect(campaign).to be_persisted
      expect(campaign.campaignable).to eq(lecture)
    end
  end

  describe "#ensure_roster_membership!" do
    let(:lecture) { create(:lecture) }
    let(:users) { create_list(:confirmed_user, 3) }

    it "adds users to the roster" do
      expect do
        lecture.ensure_roster_membership!(users.map(&:id))
      end.to change(LectureMembership, :count).by(3)

      expect(lecture.members).to include(*users)
    end

    it "respects idempotency (does not duplicate or screw up)" do
      lecture.ensure_roster_membership!([users.first.id])

      expect do
        lecture.ensure_roster_membership!(users.map(&:id))
      end.to change(LectureMembership, :count).by(2) # Only 2 new ones

      expect(lecture.members).to include(*users)
      expect(LectureMembership.where(lecture: lecture, user: users.first).count).to eq(1)
    end
  end
end
