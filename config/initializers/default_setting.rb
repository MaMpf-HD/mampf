class DefaultSetting
  PROJECT_EMAIL = ENV.fetch("PROJECT_EMAIL")
  FROM_ADDRESS = ENV.fetch("FROM_ADDRESS")
  ERROR_EMAIL = ENV.fetch("ERROR_EMAIL")
  PROJECT_NOTIFICATION_EMAIL = ENV.fetch("PROJECT_NOTIFICATION_EMAIL")
  RESEARCHGATE_LINK = "https://www.researchgate.net/project/MaMpf-Mathematische-Medienplattform".freeze
  MAMPF_STY_VERSION = "2.12".freeze
end
