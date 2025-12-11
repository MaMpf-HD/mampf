require "rails_helper"

RSpec.describe(AltchaSolution, type: :model) do
  describe "validations" do
    it "is valid with valid attributes" do
      solution = AltchaSolution.new(
        algorithm: "SHA-256",
        challenge: "challenge",
        salt: "salt",
        signature: "signature",
        number: 12_345
      )
      expect(solution).to be_valid
    end

    it "is invalid without an algorithm" do
      solution = AltchaSolution.new(algorithm: nil)
      expect(solution).not_to be_valid
      expect(solution.errors[:algorithm]).not_to be_empty
    end

    it "is invalid without a challenge" do
      solution = AltchaSolution.new(challenge: nil)
      expect(solution).not_to be_valid
      expect(solution.errors[:challenge]).not_to be_empty
    end

    it "is invalid without a salt" do
      solution = AltchaSolution.new(salt: nil)
      expect(solution).not_to be_valid
      expect(solution.errors[:salt]).not_to be_empty
    end

    it "is invalid without a signature" do
      solution = AltchaSolution.new(signature: nil)
      expect(solution).not_to be_valid
      expect(solution.errors[:signature]).not_to be_empty
    end

    it "is invalid without a number" do
      solution = AltchaSolution.new(number: nil)
      expect(solution).not_to be_valid
      expect(solution.errors[:number]).not_to be_empty
    end
  end

  describe ".verify_and_save" do
    let(:payload) do
      {
        "algorithm" => "SHA-256",
        "challenge" => "challenge",
        "salt" => "salt",
        "signature" => "signature",
        "number" => 12_345
      }
    end
    let(:encoded_payload) { Base64.encode64(payload.to_json) }

    context "with invalid base64" do
      it "returns false" do
        expect(AltchaSolution.verify_and_save("invalid-base64")).to be(false)
      end
    end

    context "with invalid json" do
      it "returns false" do
        expect(AltchaSolution.verify_and_save(Base64.encode64("invalid-json"))).to be(false)
      end
    end

    context "with invalid submission" do
      before do
        allow_any_instance_of(Altcha::Submission).to receive(:valid?).and_return(false)
      end

      it "returns false" do
        expect(AltchaSolution.verify_and_save(encoded_payload)).to be(false)
      end
    end

    context "with valid submission" do
      before do
        allow_any_instance_of(Altcha::Submission).to receive(:valid?).and_return(true)
      end

      it "creates a new solution" do
        expect do
          AltchaSolution.verify_and_save(encoded_payload)
        end.to change(AltchaSolution, :count).by(1)
      end

      it "returns true" do
        expect(AltchaSolution.verify_and_save(encoded_payload)).to be(true)
      end

      context "when replay attack occurs" do
        before do
          AltchaSolution.create!(payload)
        end

        it "returns false" do
          expect(AltchaSolution.verify_and_save(encoded_payload)).to be(false)
        end

        it "does not create a new solution" do
          expect do
            AltchaSolution.verify_and_save(encoded_payload)
          end.not_to change(AltchaSolution, :count)
        end
      end
    end
  end

  describe ".cleanup" do
    let!(:old_solution) do
      AltchaSolution.create!(algorithm: "A", challenge: "C1", salt: "S1", signature: "SIG1", number: 1,
                             created_at: 5.minutes.ago)
    end
    let!(:new_solution) do
      AltchaSolution.create!(algorithm: "A", challenge: "C2", salt: "S2", signature: "SIG2", number: 2,
                             created_at: 1.minute.ago)
    end

    before do
      allow(Altcha).to receive(:timeout).and_return(4.minutes)
    end

    it "removes solutions older than timeout" do
      expect do
        AltchaSolution.cleanup
      end.to change(AltchaSolution, :count).by(-1)
    end

    it "keeps recent solutions" do
      AltchaSolution.cleanup
      expect(AltchaSolution.exists?(new_solution.id)).to be(true)
      expect(AltchaSolution.exists?(old_solution.id)).to be(false)
    end
  end
end
