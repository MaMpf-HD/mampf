# Pages outside of any lecture that one can jump to from the command palette,
# e.g. "Profile".
module CommandPaletteGlobals
  Global = Data.define(:key, :icon, :path, :condition)

  ROUTES = Rails.application.routes.url_helpers
  EVERYONE = ->(_user) { true }

  def self.global(key, icon, path, condition: EVERYONE)
    Global.new(key: key, icon: icon, path: path, condition: condition)
  end

  ALL = [
    global("start", "bi-house", ->(_user) { ROUTES.root_path }),
    global("lecture_search", "bi-journal-text", ->(_user) { ROUTES.search_lectures_path }),
    global("search", "bi-search", ->(_user) { ROUTES.search_index_path }),
    global("comments", "bi-chat-quote", ->(_user) { ROUTES.comments_path }),
    global("notifications", "bi-bell", ->(_user) { ROUTES.notifications_path }),
    global("profile", "bi-person-circle", ->(_user) { ROUTES.edit_profile_path }),
    global("annotations", "bi-stickies", ->(_user) { ROUTES.annotations_path }),
    global("watchlists", "bi-tv", ->(_user) { ROUTES.watchlists_path }),
    global("support", "bi-life-preserver", ->(_user) { ROUTES.support_users_path },
           condition: ->(user) { user.support? || user.admin? }),
    global("deans_office", "bi-building", ->(_user) { ROUTES.deans_office_path },
           condition: ->(user) { user.deans_office? || user.admin? }),
    global("administration", "bi-tools", ->(_user) { ROUTES.administration_path },
           condition: ->(user) { user.admin? })
  ].freeze
end
