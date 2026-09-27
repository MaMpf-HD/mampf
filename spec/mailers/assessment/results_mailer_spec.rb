require "rails_helper"

describe Assessment::ResultsMailer do
  let(:course) { create(:course, title: "Algebra") }
  let(:lecture) { create(:lecture, course: course) }
  let(:exam) { create(:exam, lecture: lecture, title: "Final Exam") }

  def mail_to(user)
    create(:assessment_participation, assessment: exam.assessment, user: user,
                                      status: :reviewed, grade_numeric: 2.3, points_total: 41.5)
    described_class.with(recipient: user, assessment: exam.assessment).published_email
  end

  def bodies(mail)
    [mail.html_part, mail.text_part].map { |part| part.body.decoded }
  end

  it "points the student to the lecture in their own language" do
    mail = mail_to(create(:confirmed_user, name: "Alice", locale: "de"))

    expect(mail.subject).to include("Ergebnisse von Final Exam")
    expect(bodies(mail)).to all(include("Hallo"))
    expect(bodies(mail)).to all(include("/lectures/#{lecture.id}"))
  end

  # Grades go unencrypted by mail otherwise.
  it "leaves out grade and points" do
    mail = mail_to(create(:confirmed_user, locale: "en"))

    expect(mail.subject).to include("Results of Final Exam")
    expect(bodies(mail)).to all(satisfy { |body| !body.match?(/2[.,]3|41[.,]5/) })
  end
end
