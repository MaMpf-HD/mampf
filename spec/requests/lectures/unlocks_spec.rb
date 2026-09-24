require "rails_helper"

RSpec.describe("Lectures::Unlocks", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, passphrase: "secret") }

  before { sign_in user }

  def unlock(lecture, passphrase: nil)
    post(lecture_unlock_path(lecture), params: { passphrase: passphrase })
  end

  it "unlocks (bookmarks) the lecture with the correct passphrase" do
    unlock(lecture, passphrase: "secret")

    expect(response).to redirect_to(lecture_path(lecture))
    expect(lecture.unlocked_for?(user.reload)).to be(true)
    expect(user.lectures).to include(lecture)
  end

  it "redirects back to the lecture home page with an alert on a " \
     "wrong passphrase" do
    unlock(lecture, passphrase: "wrong")

    expect(response).to redirect_to(lecture_home_path(lecture))
    expect(flash[:alert]).to eq(I18n.t("errors.profile.passphrase"))
    expect(lecture.unlocked_for?(user.reload)).to be(false)
  end

  it "redirects with an alert also for Turbo form submissions" do
    post(lecture_unlock_path(lecture),
         params: { passphrase: "wrong" },
         headers: { "ACCEPT" => "text/vnd.turbo-stream.html, " \
                                "text/html, application/xhtml+xml" })

    expect(response).to redirect_to(lecture_home_path(lecture))
    expect(flash[:alert]).to eq(I18n.t("errors.profile.passphrase"))
  end

  it "unlocks the lecture for roster members without the passphrase" do
    create(:lecture_membership, user: user, lecture: lecture)

    unlock(lecture)

    expect(response).to redirect_to(lecture_path(lecture))
    expect(lecture.unlocked_for?(user.reload)).to be(true)
  end

  it "redirects with an alert when the lecture is not published" do
    unpublished = create(:lecture, passphrase: "secret")

    unlock(unpublished, passphrase: "secret")

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq(I18n.t("admin.lecture.no_rights"))
    expect(user.reload.lectures).not_to include(unpublished)
  end
end
