require "rails_helper"

RSpec.describe(Registration::Policy::Handler, type: :model) do
  let(:policy) { build(:registration_policy) }
  let(:handler_class) do
    Class.new(described_class) do
      public :pass_result, :fail_result
    end
  end
  let(:handler) { handler_class.new(policy) }

  describe "#evaluate" do
    it "raises NotImplementedError" do
      expect { handler.evaluate(double) }.to raise_error(NotImplementedError)
    end
  end

  describe "#summary" do
    it "returns default summary" do
      expect(handler.summary).to eq("-")
    end
  end

  describe "result helpers" do
    it "does not let pass_result metadata override reserved keys" do
      result = handler.pass_result(
        :ok,
        { foo: :bar },
        pass: false,
        code: :overridden,
        details: { bad: true },
        extra: :value
      )

      expect(result).to eq(
        pass: true,
        code: :ok,
        details: { foo: :bar },
        extra: :value
      )
    end

    it "does not let fail_result metadata override reserved keys" do
      result = handler.fail_result(
        :blocked,
        "Blocked",
        { foo: :bar },
        pass: true,
        code: :overridden,
        message: "Overridden",
        details: { bad: true },
        extra: :value
      )

      expect(result).to eq(
        pass: false,
        code: :blocked,
        message: "Blocked",
        details: { foo: :bar },
        extra: :value
      )
    end

    it "derives reason_label centrally when reason_code is provided" do
      result = handler.fail_result(
        :blocked,
        "Fallback label",
        {},
        reason_code: Registration::UserRegistration::REJECTION_REASON_CODE_WITHDRAWN_BY_TEACHER
      )

      expect(result[:reason_label])
        .to eq(I18n.t("registration.user_registration.reason_labels.withdrawn_by_teacher"))
    end
  end
end
