class DefaultSetting
  ERDBEERE_LINK = ENV.fetch("ERDBEERE_SERVER")
  MUESLI_LINK = ENV.fetch("MUESLI_SERVER")
  PROJECT_EMAIL = ENV.fetch("PROJECT_EMAIL")
  FEEDBACK_EMAIL = ENV.fetch("FEEDBACK_EMAIL")
  PROJECT_NOTIFICATION_EMAIL = ENV.fetch("PROJECT_NOTIFICATION_EMAIL")
  BLOG_LINK = ENV.fetch("BLOG")
  URL_HOST_SHORT = ENV.fetch("URL_HOST_SHORT")
  RESEARCHGATE_LINK = "https://www.researchgate.net/project/MaMpf-Mathematische-Medienplattform".freeze
  TOUR_LINK = "https://mampf.blog/ueber-mampf/".freeze
  RESOURCES_LINK = "https://mampf.blog/ressourcen-fur-editorinnen/".freeze
  MAMPF_STY_VERSION = "2.12".freeze
end
