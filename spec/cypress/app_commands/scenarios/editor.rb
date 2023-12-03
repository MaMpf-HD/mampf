# frozen_string_literal: true

User.create(name: "Max Mustermann", email: "editor@mampf.edu",
            password: "test123456", consents: true,
            locale: I18n.default_locale).confirm
