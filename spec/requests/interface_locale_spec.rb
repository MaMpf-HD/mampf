require "rails_helper"

RSpec.describe("Interface language", type: :request) do
  def lecture_in(locale)
    create(:lecture, :released_for_all, locale: locale,
                                        course: create(:course, locale: locale))
  end

  def sign_in_subscriber(locale, lecture)
    user = create(:confirmed_user, locale: locale)
    create(:lecture_user_join, user: user, lecture: lecture)
    sign_in(user)
  end

  it "shows a German lecture in the English of its reader" do
    lecture = lecture_in("de")
    sign_in_subscriber("en", lecture)

    get lecture_outline_path(lecture)

    expect(response.body).to include('<html lang="en">')
    expect(response.body).to include("Outline")
    expect(response.body).not_to include("Gliederung")
  end

  it "shows an English lecture in the German of its reader" do
    lecture = lecture_in("en")
    sign_in_subscriber("de", lecture)

    get lecture_outline_path(lecture)

    expect(response.body).to include('<html lang="de">')
    expect(response.body).to include("Gliederung")
  end

  it "answers a guest in the language of their browser" do
    get new_user_session_path, headers: { "Accept-Language" => "en-US,en;q=0.9,de;q=0.8" }

    expect(response.body).to include('<html lang="en">')
  end

  {
    "en;q=0,de;q=1" => "de",
    "de;q=0.2,en;q=0.9" => "en",
    "english" => "de"
  }.each do |header, locale|
    it "answers a guest whose browser sends #{header} in #{locale}" do
      get new_user_session_path, headers: { "Accept-Language" => header }

      expect(response.body).to include(%(<html lang="#{locale}">))
    end
  end

  it "does not keep a browser's language as the guest's choice" do
    get new_user_session_path, headers: { "Accept-Language" => "en" }
    get new_user_session_path, headers: { "Accept-Language" => "de" }

    expect(response.body).to include('<html lang="de">')
  end

  it "keeps the language a guest picks" do
    get new_user_session_path, params: { locale: "en" }
    get new_user_session_path, headers: { "Accept-Language" => "de" }

    expect(response.body).to include('<html lang="en">')
  end

  it "answers a guest whose browser asks for no language it offers in German" do
    get new_user_session_path, headers: { "Accept-Language" => "fr-FR,fr;q=0.9" }

    expect(response.body).to include('<html lang="de">')
  end
end
