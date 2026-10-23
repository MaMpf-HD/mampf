require "rails_helper"

RSpec.describe("LectureEditors", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:person) { create(:confirmed_user, email: "ada@example.com") }

  def add(email)
    post(lecture_editors_path(lecture), params: { email: email }, as: :turbo_stream)
  end

  context "as the teacher" do
    before { sign_in teacher }

    it "makes the account with that address an editor and tells them" do
      person

      expect { add(" Ada@Example.com ") }
        .to have_enqueued_mail(LectureNotificationMailer, :new_editor_email)

      expect(lecture.reload.editors).to include(person)
      options = Nokogiri::HTML(response.body).css("select[name='lecture[editor_ids][]'] option")
      expect(options.find { |o| o["value"] == person.id.to_s }["selected"]).to be_present
    end

    it "says so at the field when no account has the address" do
      add("nobody@example.com")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("lecture_editors.create.no_account"))
    end

    it "does not find an account that is not confirmed" do
      create(:user, email: "unconfirmed@example.com")

      expect { add("unconfirmed@example.com") }.not_to(change { lecture.reload.editors.count })
    end

    it "neither adds nor mails an editor or the teacher again" do
      lecture.editors << person

      expect { add(person.email) }
        .not_to have_enqueued_mail(LectureNotificationMailer, :new_editor_email)
      expect { add(teacher.email) }.not_to(change { lecture.reload.editors.count })
    end
  end

  it "lets nobody without the right to change the people of a lecture add an editor" do
    sign_in create(:confirmed_user)
    person

    add(person.email)

    expect(lecture.reload.editors).not_to include(person)
  end
end
