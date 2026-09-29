require "rails_helper"

RSpec.describe("TutorAppointments", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:person) { create(:confirmed_user, email: "grace@example.com") }

  def add(email)
    post(lecture_tutor_appointments_path(lecture), params: { email: email }, as: :turbo_stream)
  end

  context "as the teacher" do
    before { sign_in teacher }

    it "makes the account with that address a tutor and tells them" do
      person

      expect { add(" Grace@Example.com ") }
        .to have_enqueued_mail(LectureNotificationMailer, :new_tutor_email)

      expect(lecture.eligible_as_tutors).to include(person)
      expect(response.body).to include(
        I18n.t("admin.lecture.tutors_overview.added_no_tutorial_yet")
      )
    end

    it "says so at the field when no account has the address" do
      expect { add("nobody@example.com") }.not_to change(TutorAppointment, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("tutor_appointments.create.no_account"))
    end

    it "does not find an account that is not confirmed" do
      create(:user, email: "unconfirmed@example.com")

      expect { add("unconfirmed@example.com") }.not_to change(TutorAppointment, :count)
    end

    it "neither adds nor mails somebody who can be a tutor already" do
      create(:tutorial, :with_tutor_by_id, lecture: lecture, tutor_id: person.id)

      expect { add(person.email) }
        .not_to have_enqueued_mail(LectureNotificationMailer, :new_tutor_email)
      expect(TutorAppointment.count).to eq(0)
    end

    it "removes somebody added by address" do
      appointment = create_appointment

      delete(lecture_tutor_appointment_path(lecture, person), as: :turbo_stream)

      expect(TutorAppointment.exists?(appointment.id)).to be(false)
      expect(lecture.eligible_as_tutors).not_to include(person)
    end

    # Otherwise a redeemed voucher would keep somebody a tutor, and no
    # student of the lecture, for good.
    it "removes somebody who redeemed a tutor voucher" do
      Redemption.create!(voucher: create(:voucher, :tutor, lecture: lecture), user: person)

      delete(lecture_tutor_appointment_path(lecture, person), as: :turbo_stream)

      expect(lecture.tutor?(person)).to be(false)
      expect(lecture.eligible_as_tutors).not_to include(person)
    end

    it "leaves the groups of somebody removed as they are" do
      create_appointment
      create(:tutorial, :with_tutor_by_id, lecture: lecture, tutor_id: person.id)
      cohort = create(:cohort, context: lecture)
      cohort.tutors << person

      delete(lecture_tutor_appointment_path(lecture, person), as: :turbo_stream)

      expect(lecture.tutor?(person)).to be(true)
      expect(cohort.reload.tutors).to include(person)
    end
  end

  it "lets nobody without the right to change the people of a lecture add a tutor" do
    sign_in create(:confirmed_user)
    person

    expect { add(person.email) }.not_to change(TutorAppointment, :count)
  end

  it "lets nobody without the right to change the people of a lecture remove a tutor" do
    sign_in create(:confirmed_user)
    create_appointment

    delete(lecture_tutor_appointment_path(lecture, person), as: :turbo_stream)

    expect(TutorAppointment.where(user: person)).to exist
  end

  def create_appointment
    TutorAppointment.create!(lecture: lecture, user: person)
  end
end
