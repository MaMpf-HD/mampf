require "rails_helper"

RSpec.describe("Questions", type: :request) do
  let(:user) { create(:confirmed_user, admin: true) }
  let!(:question) do
    q = create(:valid_question, :with_answers, text: "Some question text")
    content = MampfExpression.new("1", "x \\lt y <script>alert('xss')</script>", "1")
    q.update(solution: Solution.new(content))
    q
  end

  before do
    sign_in user
  end

  describe "GET /questions/:id/edit" do
    it "escapes script tags in the TeX solution rendering to prevent XSS" do
      get edit_question_path(question)
      expect(response).to be_successful
      expect(response.body).not_to include("<script>alert('xss')</script>")
    end
  end
end
