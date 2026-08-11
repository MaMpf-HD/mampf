require "rails_helper"

RSpec.describe(QuizRound, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:quiz_round)).to be_valid
  end

  describe "#create_certificate_final_probe (Flipper :quiz_certificates gate)" do
    let(:quiz_round) do
      FactoryBot.build(:quiz_round).tap do |round|
        round.instance_variable_set(:@save_probe, true)
      end
    end

    context "when the feature is disabled (default)" do
      before { Flipper.disable(:quiz_certificates) }

      it "does not mint a QuizCertificate" do
        expect { quiz_round.send(:create_certificate_final_probe) }
          .not_to(change(QuizCertificate, :count))
        expect(quiz_round.certificate).to be_nil
      end
    end

    context "when the feature is enabled" do
      before { Flipper.enable(:quiz_certificates) }
      after { Flipper.disable(:quiz_certificates) }

      it "mints a QuizCertificate" do
        expect { quiz_round.send(:create_certificate_final_probe) }
          .to(change(QuizCertificate, :count).by(1))
        expect(quiz_round.certificate).to be_a(QuizCertificate)
      end
    end
  end
end
