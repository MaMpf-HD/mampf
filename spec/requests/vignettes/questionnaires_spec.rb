require "rails_helper"

RSpec.describe("Vignettes::Questionnaires", type: :request) do
  let(:lecture) { create(:lecture, :with_vignettes) }
  let(:student) { create(:confirmed_user) }
  let(:outsider) { create(:confirmed_user) }
  let(:questionnaire) { create(:vignettes_questionnaire, lecture: lecture) }

  before { student.lectures << lecture }

  def add_slides(questionnaire, count = 2)
    Array.new(count) do |index|
      slide = create(:vignettes_slide, questionnaire: questionnaire, position: index + 1)
      create(:vignettes_text_question, slide: slide)
      slide
    end
  end

  def answer_params(slide, text)
    { vignettes_answer: { slide_id: slide.id, text: text,
                          slide_statistic_attributes: { time_on_slide: 4,
                                                        total_time_on_slide: 4 } } }
  end

  describe "GET /lectures/:lecture_id/questionnaires" do
    it "lets a subscriber see the overview" do
      sign_in student
      get lecture_questionnaires_path(lecture)
      expect(response).to have_http_status(:ok)
    end

    it "sends away someone who is not part of the lecture" do
      sign_in outsider
      get lecture_questionnaires_path(lecture)
      expect(response).to redirect_to(lecture_home_path(lecture))
    end

    it "sends away everyone when the lecture does not use vignettes" do
      lecture.update!(vignettes: false)
      sign_in student
      get lecture_questionnaires_path(lecture)
      expect(response).to redirect_to(lecture_home_path(lecture))
    end

    it "hides unpublished vignettes from students" do
      questionnaire.update!(published: false)
      sign_in student
      get lecture_questionnaires_path(lecture)
      expect(response.body).not_to include(questionnaire.title)
    end

    it "shows unpublished vignettes to the teacher" do
      questionnaire.update!(published: false)
      sign_in lecture.teacher
      get lecture_questionnaires_path(lecture)
      expect(response.body).to include(questionnaire.title)
    end
  end

  describe "without data collection" do
    let!(:slides) { add_slides(questionnaire) }

    before { sign_in student }

    it "goes straight into the vignette" do
      get take_questionnaire_path(questionnaire)
      expect(response).to have_http_status(:ok)
    end

    it "measures nothing and advances by link rather than by posting" do
      get take_questionnaire_path(questionnaire)
      expect(response.body).not_to include("time-on-slide-field")
      expect(response.body)
        .to include(take_questionnaire_path(questionnaire, position: slides.second.position))
    end

    it "stores nothing at all, even when an answer is posted anyway" do
      post submit_answer_questionnaire_path(questionnaire),
           params: answer_params(slides.first, "smuggled")

      expect(Vignettes::Answer.count).to eq(0)
      expect(Vignettes::UserAnswer.count).to eq(0)
      expect(Vignettes::Codename.count).to eq(0)
      expect(Vignettes::SlideStatistic.count).to eq(0)
    end
  end

  describe "with data collection" do
    let(:questionnaire) do
      create(:vignettes_questionnaire, :collecting, lecture: lecture)
    end
    let!(:slides) { add_slides(questionnaire) }

    before { sign_in student }

    it "asks before showing the first slide" do
      get take_questionnaire_path(questionnaire)
      expect(response).to redirect_to(consent_questionnaire_path(questionnaire))
    end

    it "shows the teacher's consent text" do
      get consent_questionnaire_path(questionnaire)
      expect(response.body).to include("We store your answers under the code")
    end

    context "when the student declines" do
      before do
        post decide_consent_questionnaire_path(questionnaire), params: { consent: "decline" }
      end

      it "lets them work through the vignette" do
        expect(response).to redirect_to(take_questionnaire_path(questionnaire))
        get take_questionnaire_path(questionnaire)
        expect(response).to have_http_status(:ok)
      end

      it "keeps every slide reachable" do
        get take_questionnaire_path(questionnaire, position: slides.last.position)
        expect(response).to have_http_status(:ok)
      end

      it "stores nothing" do
        post submit_answer_questionnaire_path(questionnaire),
             params: answer_params(slides.first, "declined")

        expect(Vignettes::Answer.count).to eq(0)
        expect(Vignettes::UserAnswer.count).to eq(0)
        expect(Vignettes::Codename.count).to eq(0)
      end
    end

    context "when the student agrees to a new code" do
      it "hands out a code that belongs to nobody" do
        expect do
          post(decide_consent_questionnaire_path(questionnaire), params: { consent: "new" })
        end.to change(Vignettes::Codename, :count).by(1)

        expect(Vignettes::Codename.column_names).not_to include("user_id")
        expect(Vignettes::UserAnswer.column_names).not_to include("user_id")
      end

      it "shows the code and warns that it cannot be recovered" do
        post decide_consent_questionnaire_path(questionnaire), params: { consent: "new" }
        follow_redirect!
        expect(response.body).to include(Vignettes::Codename.last.grouped)
        expect(response.body).to include("exists nowhere but on your note")
      end

      it "stores the answer under that code" do
        post decide_consent_questionnaire_path(questionnaire), params: { consent: "new" }

        expect do
          post(submit_answer_questionnaire_path(questionnaire),
               params: answer_params(slides.first, "an answer"))
        end.to change(Vignettes::Answer, :count).by(1)

        answer = Vignettes::Answer.last
        expect(answer.text).to eq("an answer")
        expect(answer.user_answer.codename).to eq(Vignettes::Codename.last)
        expect(answer.slide_statistic.time_on_slide).to eq(4)
      end

      it "refuses an empty answer and keeps the tracked controls" do
        post decide_consent_questionnaire_path(questionnaire), params: { consent: "new" }

        expect do
          post(submit_answer_questionnaire_path(questionnaire),
               params: answer_params(slides.first, ""))
        end.not_to change(Vignettes::Answer, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("time-on-slide-field")
      end

      it "writes one answer per slide, however often a slide is submitted" do
        post decide_consent_questionnaire_path(questionnaire), params: { consent: "new" }
        post(submit_answer_questionnaire_path(questionnaire),
             params: answer_params(slides.first, "first thought"))

        expect do
          post(submit_answer_questionnaire_path(questionnaire),
               params: answer_params(slides.first, "second thought"))
        end.not_to change(Vignettes::Answer, :count)

        expect(Vignettes::Answer.last.text).to eq("first thought")
        expect(response).to redirect_to(take_questionnaire_path(questionnaire,
                                                                position: slides.second.position))
      end

      it "moves on to the next slide" do
        post decide_consent_questionnaire_path(questionnaire), params: { consent: "new" }
        post submit_answer_questionnaire_path(questionnaire),
             params: answer_params(slides.first, "an answer")
        expect(response).to redirect_to(take_questionnaire_path(questionnaire,
                                                                position: slides.second.position))
      end
    end

    context "when the student brings a code along" do
      let!(:codename) { create(:vignettes_codename) }

      it "reuses it instead of making a new one" do
        expect do
          post(decide_consent_questionnaire_path(questionnaire),
               params: { consent: "existing", pseudonym: codename.pseudonym })
        end.not_to change(Vignettes::Codename, :count)

        expect(Vignettes::UserAnswer.last.codename).to eq(codename)
      end

      it "accepts the code as it was written down, with dashes and lower case" do
        post decide_consent_questionnaire_path(questionnaire),
             params: { consent: "existing", pseudonym: codename.grouped.downcase }
        expect(Vignettes::UserAnswer.last.codename).to eq(codename)
      end

      it "quietly opens a new record for an unknown code" do
        expect do
          post(decide_consent_questionnaire_path(questionnaire),
               params: { consent: "existing", pseudonym: "ZZZZZZZZZZZZ" })
        end.to change(Vignettes::Codename, :count).by(1)
      end

      it "rejects something that cannot be a code" do
        expect do
          post(decide_consent_questionnaire_path(questionnaire),
               params: { consent: "existing", pseudonym: "nope" })
        end.not_to change(Vignettes::Codename, :count)
        expect(response).to redirect_to(consent_questionnaire_path(questionnaire))
      end
    end

    it "never says what was answered under a code" do
      other = create(:vignettes_codename)
      run = create(:vignettes_user_answer, codename: other, questionnaire: questionnaire)
      create(:vignettes_text_answer, user_answer: run, slide: slides.first,
                                     question: slides.first.question, text: "secret")

      post decide_consent_questionnaire_path(questionnaire),
           params: { consent: "existing", pseudonym: other.pseudonym }
      follow_redirect!

      expect(response.body).not_to include("secret")
    end
  end

  describe "PATCH /questionnaires/:id" do
    before { sign_in lecture.teacher }

    it "refuses to switch data collection on without a consent text" do
      patch questionnaire_path(questionnaire),
            params: { vignettes_questionnaire: { data_collection: "1", consent_text: "" } }
      expect(questionnaire.reload.data_collection).to be(false)
    end

    it "switches it on together with a consent text" do
      patch questionnaire_path(questionnaire),
            params: { vignettes_questionnaire: { data_collection: "1",
                                                 consent_text: "What we collect." } }
      expect(questionnaire.reload.data_collection).to be(true)
    end

    it "refuses a consent text that is only Trix's leftover markup" do
      patch questionnaire_path(questionnaire),
            params: { vignettes_questionnaire: { data_collection: "1",
                                                 consent_text: "<div><br></div>" } }
      expect(questionnaire.reload.data_collection).to be(false)
    end

    it "refuses to change what a published vignette's students agreed to" do
      questionnaire.update!(consent_text: "The wording they agreed under.",
                            data_collection: true)
      questionnaire.update!(editable: false)

      patch questionnaire_path(questionnaire),
            params: { vignettes_questionnaire: { data_collection: "0",
                                                 consent_text: "Something else." } }

      questionnaire.reload
      expect(questionnaire.data_collection).to be(true)
      expect(questionnaire.consent_text.to_plain_text).to eq("The wording they agreed under.")
    end

    it "does not let a student touch it" do
      sign_in student
      patch questionnaire_path(questionnaire),
            params: { vignettes_questionnaire: { data_collection: "1",
                                                 consent_text: "What we collect." } }
      expect(questionnaire.reload.data_collection).to be(false)
    end
  end

  describe "when the consent text goes missing behind the switch" do
    let(:questionnaire) do
      create(:vignettes_questionnaire, :collecting, lecture: lecture)
    end
    let!(:slides) { add_slides(questionnaire) }

    before do
      questionnaire.consent_text.destroy!
      questionnaire.reload
      sign_in student
    end

    it "does not ask the student to agree to nothing" do
      get take_questionnaire_path(questionnaire)
      expect(response).to have_http_status(:ok)
    end

    it "collects nothing, even from a session that had already agreed" do
      questionnaire.update!(consent_text: "We store your answers.")
      post decide_consent_questionnaire_path(questionnaire), params: { consent: "new" }
      questionnaire.consent_text.destroy!

      post submit_answer_questionnaire_path(questionnaire),
           params: answer_params(slides.first, "after the text was emptied")

      expect(Vignettes::Answer.count).to eq(0)
    end
  end

  describe "POST /questionnaires/:id/revoke_consent" do
    let(:questionnaire) { create(:vignettes_questionnaire, :collecting, lecture: lecture) }
    let(:codename) { create(:vignettes_codename) }
    let!(:run) { create(:vignettes_user_answer, codename: codename, questionnaire: questionnaire) }

    it "deletes everything stored under the code" do
      sign_in lecture.teacher
      expect do
        post(revoke_consent_questionnaire_path(questionnaire),
             params: { pseudonym: codename.pseudonym })
      end.to change(Vignettes::UserAnswer, :count).by(-1)
                                                  .and(change(Vignettes::Codename, :count).by(-1))
    end

    it "does not let a student delete other people's answers" do
      sign_in student
      expect do
        post(revoke_consent_questionnaire_path(questionnaire),
             params: { pseudonym: codename.pseudonym })
      end.not_to change(Vignettes::UserAnswer, :count)
    end
  end

  # form_with_generates_remote_forms is on app-wide, so a form that forgets
  # local: true is submitted by rails-ujs as XHR and its redirect goes nowhere.
  describe "the forms" do
    let(:questionnaire) do
      create(:vignettes_questionnaire, :collecting, lecture: lecture)
    end
    let!(:slides) { add_slides(questionnaire) }

    it "submits the editor's forms normally" do
      sign_in lecture.teacher
      get edit_questionnaire_path(questionnaire)
      expect(response.body).not_to include("data-remote")
    end

    it "submits the consent gate normally" do
      sign_in student
      get consent_questionnaire_path(questionnaire)
      expect(response.body).not_to include("data-remote")
    end

    it "submits the overview's forms normally" do
      sign_in lecture.teacher
      get lecture_questionnaires_path(lecture)
      expect(response.body).not_to include("data-remote")
    end
  end

  describe "POST /questionnaires" do
    let(:params) { { title: "New vignette", lecture_id: lecture.id } }

    it "lets a lecture editor create a vignette" do
      sign_in lecture.teacher
      expect do
        post(questionnaires_path, params: params)
      end.to change(Vignettes::Questionnaire, :count).by(1)
    end

    it "does not let a student create a vignette" do
      sign_in student
      expect do
        post(questionnaires_path, params: params)
      end.not_to change(Vignettes::Questionnaire, :count)
    end
  end

  describe "GET /questionnaires/:id/export_statistics" do
    it "lets a lecture editor export the answer statistics" do
      sign_in lecture.teacher
      get export_statistics_questionnaire_path(questionnaire)
      expect(response).to have_http_status(:ok)
    end

    it "does not let a student export the answer statistics" do
      sign_in student
      get export_statistics_questionnaire_path(questionnaire)
      expect(response).to redirect_to(lecture_home_path(lecture))
    end
  end
end
