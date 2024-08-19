require "rails_helper"

RSpec.describe(VoucherProcessor, type: :model) do
  describe "#call" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:voucher) { FactoryBot.create(:voucher, lecture: lecture, role: role) }
    let(:user) { FactoryBot.create(:confirmed_user) }
    let(:params) { {} }
    let(:role) { :tutor }
    let(:processor) { VoucherProcessor.new(voucher, user, params) }

    shared_examples "common voucher processing" do
      it "creates a redemption" do
        expect { processor.call }.to change { Redemption.count }.by(1)
      end

      it "subscribes the user to the lecture" do
        processor.call
        expect(user.lectures).to include(lecture)
      end

      it "creates notifications about the voucher's redemption" do
        count_before = Notification.count
        processor.call
        lecture.reload
        expect(Notification.count).to eq(count_before + lecture.editors_and_teacher.count)
      end
    end

    context "when the voucher is for a tutor" do
      let(:tutorial1) { FactoryBot.create(:tutorial, lecture: lecture) }
      let(:tutorial2) { FactoryBot.create(:tutorial, lecture: lecture) }
      let(:params) { { tutorial_ids: [tutorial1.id, tutorial2.id] } }

      include_examples "common voucher processing"

      it "adds the tutorials to the user's given tutorials" do
        processor.call
        expect(user.given_tutorials).to include(tutorial1, tutorial2)
      end

      it "does not add a tutorial if its id is not in the params" do
        tutorial3 = FactoryBot.create(:tutorial, lecture: lecture)
        processor.call
        expect(user.given_tutorials).not_to include(tutorial3)
      end

      it "creates a redemption with the claimed tutorials" do
        processor.call
        redemption = Redemption.last
        expect(redemption.claimed_tutorials).to include(tutorial1, tutorial2)
      end
    end

    context "when the voucher is for an editor" do
      let(:role) { :editor }

      include_examples "common voucher processing"

      it "adds the user to the lecture's editors" do
        processor.call
        expect(lecture.editors).to include(user)
      end
    end

    context "when the voucher is for a teacher" do
      let(:role) { :teacher }

      include_examples "common voucher processing"

      it "sets the user as the lecture's teacher" do
        processor.call
        expect(lecture.teacher).to eq(user)
      end

      it "demotes the previous teacher to an editor" do
        previous_teacher = lecture.teacher
        processor.call
        expect(lecture.editors).to include(previous_teacher)
      end

      it "invalidates the voucher" do
        processor.call
        expect(voucher.invalidated_at).not_to be_nil
      end
    end

    context "when the voucher is for a speaker" do
      let(:lecture) { FactoryBot.create(:lecture, :is_seminar) }
      let(:role) { :speaker }
      let(:talk1) { FactoryBot.create(:talk, lecture: lecture) }
      let(:talk2) { FactoryBot.create(:talk, lecture: lecture) }
      let(:params) { { talk_ids: [talk1.id, talk2.id] } }

      include_examples "common voucher processing"

      it "adds the talks to the user's given talks" do
        processor.call
        expect(user.talks).to include(talk1, talk2)
      end

      it "does not add a talk if its id is not in the params" do
        talk3 = FactoryBot.create(:talk, lecture: lecture)
        processor.call
        expect(user.talks).not_to include(talk3)
      end

      it "creates a redemption with the claimed talks" do
        processor.call
        redemption = Redemption.last
        expect(redemption.claimed_talks).to include(talk1, talk2)
      end
    end
  end
end
