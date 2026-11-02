require "rails_helper"

RSpec.describe(SubmissionsHelper, type: :helper) do
  let(:user) { create(:confirmed_user) }
  let(:lecture)          { create(:lecture) }
  let(:other_lecture)    { create(:lecture) }
  let(:tutorial)         { create(:tutorial, lecture: lecture) }
  let(:other_tutorial)   { create(:tutorial, lecture: other_lecture) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#rostered_tutorial_for" do
    before { create(:tutorial_membership, tutorial: tutorial, user: user) }

    it "only queries rostered_tutorial_in once per lecture (memoized)" do
      expect(user).to receive(:rostered_tutorial_in).once.with(lecture).and_return(tutorial)

      first  = helper.rostered_tutorial_for(lecture)
      second = helper.rostered_tutorial_for(lecture)

      expect(first).to eq(tutorial)
      expect(second).to eq(tutorial)
    end

    it "computes independently per lecture (no cross-lecture leakage)" do
      create(:tutorial_membership, tutorial: other_tutorial, user: user)

      expect(helper.rostered_tutorial_for(lecture)).to eq(tutorial)
      expect(helper.rostered_tutorial_for(other_lecture)).to eq(other_tutorial)
    end

    # The question is the seat, not what kind of lecture it is: a hand-in goes
    # to the group the reader sits in, and somebody who sits in none has no
    # group here either.
    it "returns nil for a lecture the reader sits in no group of" do
      expect(helper.rostered_tutorial_for(create(:lecture))).to be_nil
    end
  end

  describe "#tutorial_contact_line" do
    around do |example|
      I18n.with_locale(:en) { example.run }
    end

    let(:tutorial) { create(:tutorial, lecture: lecture, title: "Mo 14-16") }

    def tutor(name, email)
      create(:confirmed_user, name: name, email: email)
    end

    it "names the tutorial and where to write to its tutor" do
      tutorial.tutors << tutor("Tara Tutor", "tara@play")
      create(:tutorial_membership, tutorial: tutorial, user: user)

      expect(helper.tutorial_contact_line(lecture))
        .to eq("You are in the tutorial Mo 14-16 with Tara Tutor, reachable by email at " \
               '<a href="mailto:tara@play">tara@play</a>.')
    end

    it "gives each of several tutors their own address" do
      tutorial.tutors << [tutor("Tara Tutor", "tara@play"), tutor("Tom Tutor", "tom@play")]
      create(:tutorial_membership, tutorial: tutorial, user: user)

      line = helper.tutorial_contact_line(lecture)

      expect(line).to include('Tara Tutor (<a href="mailto:tara@play">tara@play</a>)')
      expect(line).to include('Tom Tutor (<a href="mailto:tom@play">tom@play</a>)')
    end

    it "names only the tutorial while it has no tutor" do
      create(:tutorial_membership, tutorial: tutorial, user: user)

      expect(helper.tutorial_contact_line(lecture)).to eq("You are in the tutorial Mo 14-16.")
    end

    it "says nothing to a reader in no tutorial" do
      expect(helper.tutorial_contact_line(lecture)).to be_nil
    end
  end

  describe "#roster_cache" do
    it "returns the same hash across multiple calls within one helper instance" do
      first  = helper.roster_cache
      second = helper.roster_cache

      expect(first).to equal(second) # same object, not just equal value
    end
  end
end
