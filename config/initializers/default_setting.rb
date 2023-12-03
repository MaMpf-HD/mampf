class DefaultSetting
  ERDBEERE_LINK = ENV.fetch("ERDBEERE_SERVER", nil)
  MUESLI_LINK = ENV.fetch("MUESLI_SERVER", nil)
  PROJECT_EMAIL = ENV.fetch("PROJECT_EMAIL", nil)
  PROJECT_NOTIFICATION_EMAIL = ENV.fetch("PROJECT_NOTIFICATION_EMAIL", nil)
  BLOG_LINK = ENV.fetch("BLOG", nil)
  URL_HOST_SHORT = ENV.fetch("URL_HOST_SHORT", nil)
  RESEARCHGATE_LINK = "https://www.researchgate.net/project/MaMpf-Mathematische-Medienplattform"
  TOUR_LINK = "https://mampf.blog/ueber-mampf/"
  RESOURCES_LINK = "https://mampf.blog/ressourcen-fur-editorinnen/"
  MAMPF_STY_VERSION = "2.12"
end
