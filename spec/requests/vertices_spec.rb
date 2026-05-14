require "rails_helper"

RSpec.describe("Vertices Security", type: :request) do
  describe "POST /vertices" do
    let(:user) do
      create(:user, admin: true, consents: true, confirmed_at: Time.zone.now)
    end
    let(:course) { create(:course) }
    let(:quiz) do
      q = create(:quiz, teachable: course, editors: [user],
                        description: "Test Quiz")
      q.update(
        quiz_graph: QuizGraph.new(vertices: {}, edges: {}, root: 0,
                                  default_table: {})
      )
      q
    end

    before do
      sign_in user
    end

    it "safely rejects arbitrary model injection in sort" do
      expect do
        post(quiz_vertices_path(quiz), params: {
               vertex: { sort: "Logger", label: "Malicious" }
             }, xhr: true)
      end.not_to(change do
        [Question.count, Remark.count, quiz.reload.quiz_graph.vertices]
      end)

      expect(response).to be_successful
      expect(response.body).to include(edit_quiz_path(quiz))
    end

    it "creates a question vertex for Question sort" do
      expect do
        post(quiz_vertices_path(quiz), params: {
               vertex: { sort: "Question", label: "Valid Question" },
               branching: {}
             }, xhr: true)
      end.to change(Question, :count).by(1)
         .and(change { quiz.reload.quiz_graph.vertices.size }.by(1))

      question = Question.order(:id).last

      expect(response).to be_successful
      expect(response.body).to include(edit_quiz_path(quiz))
      expect(question.description).to eq("Valid Question")
      expect(question.teachable).to eq(course)
      expect(question.editors).to contain_exactly(user)
      expect(quiz.reload.quiz_graph.vertices).to eq(
        1 => { type: "Question", id: question.id }
      )
    end

    it "creates a remark vertex for Remark sort" do
      expect do
        post(quiz_vertices_path(quiz), params: {
               vertex: { sort: "Remark", label: "Valid Remark" },
               branching: {}
             }, xhr: true)
      end.to change(Remark, :count).by(1)
         .and(change { quiz.reload.quiz_graph.vertices.size }.by(1))

      remark = Remark.order(:id).last

      expect(response).to be_successful
      expect(response.body).to include(edit_quiz_path(quiz))
      expect(remark.description).to eq("Valid Remark")
      expect(remark.teachable).to eq(course)
      expect(remark.editors).to contain_exactly(user)
      expect(quiz.reload.quiz_graph.vertices).to eq(
        1 => { type: "Remark", id: remark.id }
      )
    end
  end
end
