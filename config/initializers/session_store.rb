Rails.application.config.session_store :cookie_store,
                                       key: "_mampf_session",
                                       same_site: :strict