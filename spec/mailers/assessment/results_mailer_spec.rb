require "rails_helper"

describe Assessment::ResultsMailer do
  let(:course) { create(:course, title: "Algebra") }
  let(:lecture) { create(:lecture, course: course) }
  let(:exam) { create(:exam, lecture: lecture, title: "Final Exam") }
  let(:students) { create_list(:confirmed_user, 2, locale: "de") }

  def mail(locale)
    students.each do |student|
      create(:assessment_participation, assessment: exam.assessment, user: student,
                                        status: :reviewed, grade_numeric: 2.3,
                                        points_total: 41.5)
    end
    described_class.with(recipients: students.map(&:id), locale: locale,
                         assessment: exam.assessment).published_email
  end

  def bodies(mail)
    [mail.html_part, mail.text_part].map { |part| part.body.decoded }
  end

  it "goes to everyone at once, in bcc, and points them to the lecture" do
    mail = mail(:de)

    expect(mail.bcc).to match_array(students.map(&:email))
    expect(mail.to).to be_blank
    expect(mail.subject).to include("Ergebnisse von Final Exam")
    expect(bodies(mail)).to all(include("/lectures/#{lecture.id}"))
  end

  # Grades go unencrypted by mail otherwise, and the greeting names nobody,
  # as the same mail goes to all.
  it "leaves out grades, points and names" do
    mail = mail(:en)

    expect(mail.subject).to include("Results of Final Exam")
    expect(bodies(mail)).to all(satisfy { |body| !body.match?(/2[.,]3|41[.,]5/) })
    expect(bodies(mail)).to all(satisfy { |body| students.none? { |s| body.include?(s.name) } })
  end
end
